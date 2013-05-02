#include <linux/module.h>
#include <asm/uaccess.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
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

struct scull_qset *scull_follow (struct scull_dev *dev, int n)
{
	struct scull_qset *qs = dev->data;

	if (!qs)
	{
		qs = dev->data = kmalloc (sizeof (struct scull_qset), GFP_KERNEL);
		if (qs == NULL)
			return NULL;
		memset (qs, 0, sizeof (struct scull_qset));
	}

	while (n--)
	{
		if (! qs->next)
		{
			qs->next = kmalloc (sizeof (struct scull_qset), GFP_KERNEL);
			if (qs->next == NULL)
				return NULL;
			memset (qs, 0, sizeof (struct scull_qset));
		}
		qs = qs->next;
	}

	return qs;
}

ssize_t scull_read (struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
	struct scull_dev *dev = filp->private_data;
	struct scull_qset *dptr;
	int quantum = dev->quantum;
	int qset = dev->qset;
	int itemsize = quantum * qset;
	int item, s_pos, q_pos, rest;
	ssize_t retval = 0;

	if (down_interruptible (&dev->sem))
		return -ERESTARTSYS;

	if (*f_pos >= dev->size)
		goto out;
	if (*f_pos + count > dev->size)
		count = dev->size - *f_pos;

	item = (long)*f_pos / itemsize;
	rest = (long)*f_pos % itemsize;
	s_pos = rest / quantum;
	q_pos = rest % quantum;

	dptr = scull_follow (dev, item);
	if (dptr == NULL || !dptr->data || !dptr->data[s_pos])
		goto out;

	if (count > quantum - q_pos)
		count = quantum - q_pos;

	if (copy_to_user (buf, dptr->data[s_pos] + q_pos, count))
	{
		retval = -EFAULT;
		goto out;
	}
	*f_pos += count;
	retval = count;

out:
	up (&dev->sem);
	return retval;
}

ssize_t scull_write (struct file *filp, const char __user *buf, size_t count, loff_t *f_pos)
{
	struct scull_dev *dev = filp->private_data;
	struct scull_qset *dptr;
	int quantum = dev->quantum;
	int qset = dev->qset;
	int itemsize = quantum * qset;
	int item, s_pos, q_pos, rest;
	ssize_t retval = -ENOMEM;

	if (down_interruptible (&dev->sem))
		return -ERESTARTSYS;

	item = (long)*f_pos / itemsize;	/* index of link node */
	rest = (long)*f_pos % itemsize;	/*  offset in a link node */
	s_pos = rest / quantum;	/* index of qset */
	q_pos = rest % quantum; /* offset in qset */

	dptr = scull_follow (dev, item);
	if (dptr == NULL)
		goto out;
	if (!dptr->data)
	{
		dptr->data = kmalloc (qset * sizeof (char *), GFP_KERNEL);
		if (!dptr->data)
			goto out;
		memset (dptr->data, 0, qset * sizeof (char *));
	}
	if (!dptr->data[s_pos])
	{
		dptr->data[s_pos] = kmalloc (quantum, GFP_KERNEL);
		if (!dptr->data[s_pos])
			goto out;
	}

	if (count > quantum - q_pos)
		count = quantum - q_pos;

	if (copy_from_user (dptr->data[s_pos] + q_pos, buf, count))
	{
		retval = -EFAULT;
		goto out;
	}
	*f_pos += count;
	retval = count;

	if (dev->size < *f_pos)
		dev->size = *f_pos;

out:
	up (&dev->sem);
	return retval;
}

loff_t scull_llseek (struct file *filp, loff_t off, int whence)
{
	struct scull_dev *dev = filp->private_data;
	loff_t newpos;

	switch (whence)
	{
		case 0: /* SEEK_SET */
			newpos = off;
			break;
		case 1: /* SEEK_CUR */
			newpos = filp->f_pos + off;
			break;
		case 2: /* SEEK_END */
			newpos = dev->size + off;
			break;
		default:
			return -EINVAL;
	}
	if (newpos < 0) return -EINVAL;
	filp->f_pos = newpos;
	return newpos;
}

long scull_ioctl (struct file *filp, unsigned int cmd, unsigned long arg)
{
	int err = 0, tmp;
	int retval = 0;

	if (_IOC_TYPE(cmd) != SCULL_IOC_MAGIC) return -ENOTTY;
	if (_IOC_NR(cmd) > SCULL_IOC_MAXNR) return -ENOTTY;

	if (_IOC_DIR(cmd) & _IOC_READ)
		err = !access_ok (VERIFY_WRITE, (void __user *)arg, _IOC_SIZE(cmd));
	else if (_IOC_DIR(cmd) & _IOC_WRITE)
		err = !access_ok (VERIFY_READ, (void __user *)arg, _IOC_SIZE(cmd));
	if (err) return -EFAULT;

	switch (cmd)
	{
		case SCULL_IOCRESET:
			scull_quantum = SCULL_QUANTUM;
			scull_qset = SCULL_QSET;
			break;

		case SCULL_IOCSQUANTUM:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			retval = __get_user (scull_quantum, (int __user *)arg);
			break;
			
		case SCULL_IOCTQUANTUM:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			scull_quantum = arg;
			break;

		case SCULL_IOCGQUANTUM:
			retval = __put_user (scull_quantum, (int __user *)arg);
			break;

		case SCULL_IOCQQUANTUM:
			return scull_quantum;

		case SCULL_IOCXQUANTUM:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			tmp = scull_quantum;
			retval = __get_user (scull_quantum, (int __user *)arg);
			if (retval == 0)
				retval = __put_user (tmp, (int __user *)arg);
			break;

		case SCULL_IOCHQUANTUM:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			tmp = scull_quantum;
			scull_quantum = arg;
			return tmp;

		case SCULL_IOCSQSET:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			retval = __get_user (scull_qset, (int __user *)arg);
			break;

		case SCULL_IOCTQSET:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			scull_qset = arg;
			break;

		case SCULL_IOCGQSET:
			retval = __put_user (scull_qset, (int __user *)arg);
			break;

		case SCULL_IOCQQSET:
			return scull_qset;

		case SCULL_IOCXQSET:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			tmp = scull_qset;
			retval = __get_user (scull_qset, (int __user *)arg);
			if (retval == 0)
				retval = __put_user (tmp, (int __user *)arg);
			break;

		case SCULL_IOCHQSET:
			if (!capable (CAP_SYS_ADMIN))
				return -EPERM;
			tmp = scull_qset;
			scull_qset = arg;
			return tmp;

		case SCULL_P_IOCTSIZE:
			/* PH */
			break;

		case SCULL_P_IOCQSIZE:
			/* PH */
			return 0;
			break;

		default:
			return -ENOTTY;
	}
	return retval;
}

int scull_open (struct inode *inode, struct file *filp)
{
	struct scull_dev *dev;

	dev = container_of (inode->i_cdev, struct scull_dev, cdev);
	filp->private_data = dev;

	if ((filp->f_flags & O_ACCMODE) == O_WRONLY)
	{
		if (down_interruptible (&dev->sem) != 0)
			return -ERESTARTSYS;
		scull_trim (dev);
		up (&dev->sem);
	}

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

static void *scull_seq_start (struct seq_file *s, loff_t *pos)
{
	if (pos)
		PDEBUG (KERN_ALERT "%s *pos=%lld\n", __func__, *pos);
	if (*pos >= scull_nr_devs)
		return NULL;
	return scull_devices + *pos;
}

static void *scull_seq_next (struct seq_file *s, void *v, loff_t *pos)
{
	if (pos)
		PDEBUG (KERN_ALERT "%s *pos=%lld\n", __func__, *pos);
	(*pos)++;
	if (*pos >= scull_nr_devs)
		return NULL;
	return scull_devices + *pos;
}

static void scull_seq_stop (struct seq_file *s, void *v)
{
}

static int scull_seq_show (struct seq_file *s, void *v)
{
	struct scull_dev *dev = (struct scull_dev *)v;
	struct scull_qset *d;
	int i;

	if (down_interruptible (&dev->sem))
		return -ERESTARTSYS;
	seq_printf (s, "\nDevice %i; qset %i, q %i, sz %li\n", (int) (dev - scull_devices), dev->qset, dev->quantum, dev->size);
	for (d = dev->data; d; d = d->next)
	{
		seq_printf (s, "  item at %p, qset at %p\n", d, d->data);
		if (d->data && !d->next) /* dump only the last item */
			for (i = 0; i < dev->qset; i++)
				if (d->data[i])
					seq_printf (s, "    % 4i: %8p\n", i, d->data[i]);
	}
	up (&dev->sem);
	return 0;
}

static struct seq_operations scull_seq_ops = 
{
	.start = scull_seq_start,
	.next = scull_seq_next,
	.stop = scull_seq_stop,
	.show = scull_seq_show,
};

static int scull_proc_open (struct inode *inode, struct file *file)
{
	return seq_open (file, &scull_seq_ops);
}

static struct file_operations scull_proc_ops = 
{
	.owner 		= THIS_MODULE,
	.open 		= scull_proc_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= seq_release,
};

int scull_read_procmem (char *buf, char **start, off_t offset, int count, int *eof, void *data)
{
	int i, j, len = 0;
	int limit = count - 80;
	struct scull_dev *d;
	struct scull_qset *qs;

	for (i = 0; i < scull_nr_devs && len <= limit; i++)
	{
		d = &scull_devices[i];
		if (down_interruptible (&d->sem))
			return -ERESTARTSYS;
		qs = d->data;
		len += sprintf (buf+len, "\nDevice %i,: qset %i, q %i, sz %li\n", i, d->qset, d->quantum, d->size);
		for (; qs && len <= limit; qs = qs->next) /* travesal list */
		{
			len += sprintf (buf + len, "  item at %p, qset at %p\n", qs, qs->data);
			if (qs->data && !qs->next)	/* dump last qset */
				for (j = 0; j < d->qset; j++)
					if (qs->data[j])
						len += sprintf (buf + len, "   % 4i: %8p\n", j, qs->data[j]);
		}
		up(&scull_devices[i].sem);
	}
	*eof = 1;
	return len;
}

static void scull_create_proc (void)
{
	struct proc_dir_entry *entry;
	create_proc_read_entry ("scullmem", 0 /* default mode */, 
			NULL /* partent dir */, scull_read_procmem,
			NULL /*client data */);
	entry = create_proc_entry ("scullseq", 0, NULL);
	if (entry)
		entry->proc_fops = &scull_proc_ops;
}

static void scull_remove_proc (void)
{
	remove_proc_entry ("scullmem", NULL);
	remove_proc_entry ("scullseq", NULL);
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

#ifdef SCULL_DEBUG 
	scull_remove_proc ();
#endif /* SCULL_DEBUG */

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

#ifdef SCULL_DEBUG
	scull_create_proc ();
#endif /* SCULL_DEBUG */

	return 0;

fail:
	scull_cleanup_module();
	return result;
}

module_init (scull_init_module);
module_exit (scull_cleanup_module);
