#include <linux/module.h>
#include "scull.h"

int scull_major = SCULL_MAJOR;
int scull_minor = 0;
int scull_nr_devs = SCULL_NR_DEVS;
int scull_quantum = SCULL_QUANTUM;
int scull_qset = SCULL_QSET;

/* /sys/module/<module>/parameters */
module_param (scull_major, int, S_IRUGO);
module_param (scull_minor, int, S_IRUGO);
module_param (scull_nr_devs, int, S_IRUGO);
module_param (scull_quantum, int, S_IRUGO);
module_param (scull_qset, int, S_IRUGO);

MODULE_LICENSE ("GPL");

struct scull_dev *scull_devices;

struct file_operations scull_fops = 
{
	.owner = 	THIS_MODULE,
	.llseek = 	scull_llseek,
	.read =		scull_read,
	.write = 	scull_write,
	.unlocked_ioctl = scull_ioctl,
	.open = 	scull_open,
	.release =	scull_release,
};

ssize_t scull_read (struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
	return 0;
}

ssize_t scull_write (struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
	return 0;
}

loff_t scull_llseek (struct file *filp, loff_t off, int whence)
{
	return 0;
}

long scull_ioctl (struct file *filp, unsigned int cmd, unsigned long arg)
{
	return 0;
}

int scull_open (struct inode *inode, struct file *filp)
{
	return 0;
}

int scull_release (struct inode *inode, struct file *filep)
{
	return 0;
}



static void scull_setup_cdev (struct scull_dev *dev, int index)
{
	int err;
	int devno = MKDEV(scull_major, scull_minor + index);

	cdev_init (&dev->cdev, &scull_fops);
	dev->cdev.owner = THIS_MODULE;
	// dev->cdev.ops = &scull_fops; /* we don't need to do that */
	err = cdev_add (&dev->cdev, devno, 1);
	if (err)
		printk (KERN_NOTICE "Error %d adding scull%d", err, index);
}

int scull_trim (struct scull_dev *dev)
{
	struct scull_qset *next, *dptr;
	int qset = dev->qset;
	int i;

	for (dptr = dev->data; dptr; dptr = next)
	{
		if (dptr->data)
		{
			for (i = 0; i < qset; i++)
				kfree (dptr->data[i]); /* kfree(NULL) is OK */
			kfree (dptr->data);
			dptr->data = NULL;
		}
		next = dptr->next;
		kfree (dptr);
	}
	dev->size = 0;
	dev->quantum = scull_quantum;
	dev->qset = scull_qset;
	dev->data = NULL;
	return 0;
	return 0;
}

void scull_cleanup_module (void)
{
	int i;
	dev_t devno = MKDEV (scull_major, scull_minor);

	PDEBUG ("goodbye cruial world!\n");
	
	if (scull_devices)
	{
		for (i = 0; i < scull_nr_devs; i++)
		{
			scull_trim (&scull_devices[i]);
			cdev_del (&scull_devices[i].cdev);
		}
		kfree (scull_devices);
	}

	unregister_chrdev_region (devno, scull_nr_devs);
}

int scull_init_module (void)
{
	int result, i;
	dev_t dev = 0;

	PDEBUG ("hello world!\n");

	if (scull_major)
	{
		dev = MKDEV (scull_major, scull_minor);
		result = register_chrdev_region (dev, scull_nr_devs, "scull");
	}
	else
	{
		result = alloc_chrdev_region (&dev, scull_minor, scull_nr_devs, "scull");
		scull_major = MAJOR(dev);
	}
	if (result < 0) {
		printk (KERN_WARNING "scull: can't get major %d\n", scull_major);
		return result;
	}

	scull_devices = kmalloc (scull_nr_devs * sizeof (struct scull_dev), GFP_KERNEL);
	if (scull_devices == NULL)
	{
		result = -ENOMEM;
		goto fail;
	}
	memset (scull_devices, 0, scull_nr_devs * sizeof (struct scull_dev));

	for (i = 0; i < scull_nr_devs; i++)
	{
		scull_devices[i].quantum = scull_quantum;
		scull_devices[i].qset = scull_qset;
		sema_init (&scull_devices[i].sem, 1);
		scull_setup_cdev (&scull_devices[i], i);
	}

	return 0;

fail:
	scull_cleanup_module();
	return result;
}

module_init (scull_init_module);
module_exit (scull_cleanup_module);
