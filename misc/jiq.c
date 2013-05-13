#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/sched.h>
#include <linux/proc_fs.h>
#include <linux/interrupt.h>

MODULE_LICENSE ("GPL");

static long delay = 1;
module_param (delay, long, 0);

#define LIMIT 512
// #define SCUEDULE_QUEUE ((task_queue *) 1)

static DECLARE_WAIT_QUEUE_HEAD (jiq_wait);

static struct clientdata
{
	struct work_struct jiq_work;
	struct delayed_work jiq_delayed_work;
	int len;
	char *buf;
	unsigned long jiffies;
	long delay;
} jiq_data;

static void jiq_print_tasklet (unsigned long);
static DECLARE_TASKLET (jiq_tasklet, jiq_print_tasklet, (unsigned long)&jiq_data);


static int jiq_print (void *ptr)
{
	struct clientdata *data = ptr;
	int len = data->len;
	char *buf = data->buf;

	unsigned long j = jiffies;

	if (len > LIMIT)
	{
		wake_up_interruptible (&jiq_wait);
		return 0;
	}

	if (len == 0)
		len = sprintf (buf, "	time	delta	preempt	pid	cpu	command\n");
	else
		len = 0;

	len += sprintf (buf + len, "%9li	%4li	%3i	%5i %3i	%s\n", j, j - data->jiffies,
			preempt_count(), current->pid, smp_processor_id(),
			current->comm);

	data->len += len;
	data->buf += len;
	data->jiffies = j;
	return 1;
}

static void jiq_print_wq (struct work_struct *work)
{
	struct clientdata *data = container_of (work, struct clientdata, jiq_work);
	
	printk (KERN_ALERT "%s() begin\n", __func__);
	
	if (!jiq_print (data))
		return;

	schedule_work (&jiq_data.jiq_work);
	printk (KERN_ALERT "%s() end\n", __func__);
}


static void jiq_print_wq_delayed (struct work_struct *work)
{

	struct clientdata *data = container_of (work, struct clientdata, jiq_delayed_work.work);
	printk (KERN_ALERT "%s() begin\n", __func__);
	
	if (!jiq_print (data))
		return;

	schedule_delayed_work (&jiq_data.jiq_delayed_work, data->delay);
	printk (KERN_ALERT "%s() end\n", __func__);
}

static int jiq_read_wq (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	DEFINE_WAIT (wait);

	printk (KERN_ALERT "%s() begin\n", __func__);
	jiq_data.len = 0;
	jiq_data.buf = buf;
	jiq_data.jiffies = jiffies;
	jiq_data.delay = 0;
	
	prepare_to_wait (&jiq_wait, &wait, TASK_INTERRUPTIBLE);
	schedule_work (&jiq_data.jiq_work);
	schedule ();
	finish_wait (&jiq_wait, &wait);

	*eof = 1;
	printk (KERN_ALERT "%s() end\n", __func__);
	return jiq_data.len;
}

static int jiq_read_wq_delayed (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	DEFINE_WAIT (wait);

	printk (KERN_ALERT "%s() begin\n", __func__);
	jiq_data.len = 0;
	jiq_data.buf = buf;
	jiq_data.jiffies = jiffies;
	jiq_data.delay = delay;
	
	prepare_to_wait (&jiq_wait, &wait, TASK_INTERRUPTIBLE);
	schedule_delayed_work(&jiq_data.jiq_delayed_work, delay);
	schedule ();
	finish_wait (&jiq_wait, &wait);

	*eof = 1;
	printk (KERN_ALERT "%s() end\n", __func__);
	return jiq_data.len;
}

static void jiq_print_tasklet (unsigned long ptr)
{
	if (jiq_print ((void *)ptr))
		tasklet_schedule (&jiq_tasklet);
}

static struct timer_list jiq_timer;

static void jiq_timedout (unsigned long ptr)
{
	jiq_print ((void *)ptr);
	wake_up_interruptible (&jiq_wait);
}

static int jiq_read_run_timer (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	jiq_data.len = 0;
	jiq_data.buf = buf;
	jiq_data.jiffies = jiffies;

	init_timer (&jiq_timer);
	jiq_timer.function = jiq_timedout;
	jiq_timer.data = (unsigned long)&jiq_data;
	jiq_timer.expires = jiffies + HZ;

	jiq_print (&jiq_data);
	add_timer (&jiq_timer);
	interruptible_sleep_on (&jiq_wait);
	del_timer_sync (&jiq_timer);

	*eof = 1;
	return jiq_data.len;
}

static int jiq_read_tasklet (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	jiq_data.len = 0;
	jiq_data.buf = buf;
	jiq_data.jiffies = jiffies;

	tasklet_schedule (&jiq_tasklet);
	interruptible_sleep_on (&jiq_wait);

	*eof = 1;
	return jiq_data.len;
}

static int jiq_init (void)
{
	INIT_WORK (&jiq_data.jiq_work, jiq_print_wq);
	INIT_DELAYED_WORK (&jiq_data.jiq_delayed_work, jiq_print_wq_delayed);

	create_proc_read_entry ("jiqwq", 0, NULL, jiq_read_wq, NULL);
	create_proc_read_entry ("jiqwqdelay", 0, NULL, jiq_read_wq_delayed, NULL);
	create_proc_read_entry ("jitimer", 0, NULL, jiq_read_run_timer, NULL);
	create_proc_read_entry ("jiqtasklet", 0, NULL, jiq_read_tasklet, NULL);

	return 0;
}

static void jiq_cleanup (void)
{
	remove_proc_entry ("jiqwq", NULL);
	remove_proc_entry ("jiqwqdelay", NULL);
	remove_proc_entry ("jitimer", NULL);
	remove_proc_entry ("jiqtasklet", NULL);
}

module_init (jiq_init);
module_exit (jiq_cleanup);
