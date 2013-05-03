#include <linux/module.h>
#include <linux/sched.h>
#include "scull.h"

struct scull_pipe
{
	wait_queue_head_t inq, outq;
	char *buffer, *end;
	char *rp, *wp;
	int nreaders, nwriters;
	struct fasync_struct *async_queue;
	struct semaphore sem;
	struct cdev cdev;
};

static int scull_p_nr_devs = SCULL_P_NR_DEVS;
int scull_p_buffer = SCULL_P_BUFFER;
dev_t scull_p_devno;
module_param (scull_p_nr_devs, int, 0);
module_param (scull_p_buffer, int, 0);

static struct scull_pipe *scull_p_devices;

struct file_operations scull_pipe_fops =
{
	.owner = THIS_MODULE,
};

static void scull_p_setup_cdev (struct scull_pipe *dev, int index)
{
	int err, devno = scull_p_devno + index;
	cdev_init (&dev->cdev, &scull_pipe_fops);
	dev->cdev.owner = THIS_MODULE;
	err = cdev_add (&dev->cdev, devno, 1);
	if (err)
		printk (KERN_NOTICE "Error %d addint scullpipe%d", err, index);
}

int scull_p_init (dev_t firstdev)
{
	int  i, result;

	result = register_chrdev_region (firstdev, scull_p_nr_devs, "scullp");
	if (result < 0)
	{
		printk (KERN_NOTICE "Unable to get scullp region, error %d\n", result);
		return 0;
	}
	scull_p_devno = firstdev;
	scull_p_devices = kmalloc (scull_p_nr_devs * sizeof (struct scull_pipe), GFP_KERNEL);
	if (scull_p_devices == NULL)
	{
		unregister_chrdev_region (firstdev, scull_p_nr_devs);
		return 0;
	}
	memset (scull_p_devices, 0, scull_p_nr_devs * sizeof (struct scull_pipe));
	
	for (i = 0; i < scull_p_nr_devs; i++)
	{
		init_waitqueue_head (&(scull_p_devices[i].inq));
		init_waitqueue_head (&(scull_p_devices[i].outq));
		sema_init (&scull_p_devices[i].sem, 1);
		scull_p_setup_cdev (scull_p_devices + i, i);
	}

#ifdef SCULL_DEBUG
//	create_proc_read_entry ("scullpipe", 0, NULL, scull_read_p_mem, NULL);
#endif

	return scull_p_nr_devs;
}

void scull_p_cleanup (void)
{
	int i;

#ifdef SCULL_DEBUG
//	remove_proc_entry ("scullpipe", NULL);
#endif 

	if (!scull_p_devices)
		return;

	for (i = 0; i < scull_p_nr_devs; i++)
	{
		cdev_del (&scull_p_devices[i].cdev);
		kfree (scull_p_devices[i].buffer);
	}
	kfree (scull_p_devices);
	unregister_chrdev_region (scull_p_devno, scull_p_nr_devs);
	scull_p_devices = NULL;
}
