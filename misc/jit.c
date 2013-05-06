#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/sched.h>
#include <linux/wait.h>
#include <linux/interrupt.h>

int delay = HZ;
int tdelay = 10;
module_param (delay, int, 0);
module_param (tdelay, int, 0);

MODULE_LICENSE("GPL");

enum jit_files 
{
	JIT_BUSY,
	JIT_SCHED,
	JIT_QUEUE,
	JIT_SCHEDTO,
};

struct jit_data {
	struct timer_list timer;
	struct tasklet_struct tlet;
	int hi;
	wait_queue_head_t wait;
	unsigned long prevjiffies;
	unsigned char *buf;
	int loops;
};
#define JIT_ASYNC_LOOP 5

int jit_currentime (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	return 0;
}

int jit_fn (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	return 0;
}

int jit_timer (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	return 0;
}

int jit_tasklet (char *buf, char **start, off_t offset, int len, int *eof, void *data)
{
	return 0;
}


int __init jit_init (void)
{
	create_proc_read_entry ("currentime", 0, NULL, jit_currentime, NULL);
	create_proc_read_entry ("jitbusy", 0, NULL, jit_fn, (void *)JIT_BUSY);
	create_proc_read_entry ("jitsched", 0, NULL, jit_fn, (void *)JIT_SCHED);
	create_proc_read_entry ("jitqueue", 0, NULL, jit_fn, (void *)JIT_QUEUE);
	create_proc_read_entry ("jitschedto", 0, NULL, jit_fn, (void *)JIT_SCHEDTO);

	create_proc_read_entry ("jitimer", 0, NULL, jit_timer, NULL);
	create_proc_read_entry ("jitasklet", 0, NULL, jit_tasklet, NULL);
	create_proc_read_entry ("jitasklethi", 0, NULL, jit_tasklet, (void *)1);

	return 0;
}

void __exit jit_cleanup (void)
{
	remove_proc_entry ("currentime", NULL);
	remove_proc_entry ("jitbusy", NULL);
	remove_proc_entry ("jitsched", NULL);
	remove_proc_entry ("jitqueue", NULL);
	remove_proc_entry ("jitschedto", NULL);

	remove_proc_entry ("jitmer", NULL);
	remove_proc_entry ("jitasklet", NULL); 
	remove_proc_entry ("jitasklethi", NULL); 
}

module_init (jit_init);
module_exit (jit_cleanup);
