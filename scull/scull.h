#ifndef _SCULL_H_
#define _SCULL_H_

#include <linux/cdev.h>
#include <linux/fs.h>

#undef PDEBUG
#ifdef SCULL_DEBUG
#  ifdef __KERNEL__
	/* kernel sapce */
#    define PDEBUG(fmt, args...) printk(KERN_DEBUG "scull: " fmt, ## args)
#  else
    /* user space */
#    define PDEBUG(fmt, args...) fprintf(stderr, fmt, ## args)
#  endif
#else
#  define PDEBUG(fmt, args...)
#endif

#ifndef SCULL_QUANTUM
#define SCULL_QUANTUM 4096
#endif

#ifndef SCULL_QSET
#define SCULL_QSET 1024
#endif


#ifndef SCULL_MAJOR
#define SCULL_MAJOR 0
#endif

#ifndef SCULL_NR_DEVS
#define SCULL_NR_DEVS 4
#endif

#ifndef SCULL_P_NR_DEVS
#define SCULL_P_NR_DEVS 4
#endif

#ifndef SCULL_P_BUFFER
#define SCULL_P_BUFFER 4096
#endif 

struct scull_qset {
	void **data;
	struct scull_qset *next;
};


struct scull_dev {
	struct scull_qset *data;
	int quantum;
	int qset;
	unsigned long size;
	unsigned int access_key;
	struct semaphore sem;	/* linux/fs.h */
	struct cdev cdev;
};

extern int scull_major;
extern int scull_nr_devs;
extern int scull_quantum;
extern int scull_qset;

int scull_trim (struct scull_dev *dev);
ssize_t scull_read (struct file *filp, char __user *buf, size_t count, loff_t *f_pos);
ssize_t scull_write (struct file *filp, const char __user *buf, size_t count, loff_t *f_pos);
loff_t scull_llseek (struct file *filp, loff_t off, int whence);
long scull_ioctl (struct file *filp, unsigned int cmd, unsigned long arg);
int scull_open (struct inode *inode, struct file *filp);
int scull_release (struct inode *inode, struct file *filep);

#define SCULL_IOC_MAGIC 'k'

#define SCULL_IOCRESET _IO(SCULL_IOC_MAGIC, 0)
/*
 * S means 'Set' trough a ptr
 * T means 'Tell' directly with the argument value
 * G means 'Get' reply by setting through a ptr
 * Q means 'Query' response is on the return value
 * X means 'eXchange' switch G and S atomically
 * H means 'sHift' switch T and Q atomically
 */

 #define SCULL_IOCSQUANTUM	_IOW(SCULL_IOC_MAGIC, 1, int)
 #define SCULL_IOCSQSET 	_IOW(SCULL_IOC_MAGIC, 2, int)
 #define SCULL_IOCTQUANTUM	_IO(SCULL_IOC_MAGIC, 3)
 #define SCULL_IOCTQSET 	_IO(SCULL_IOC_MAGIC, 4)
 #define SCULL_IOCGQUANTUM	_IOR(SCULL_IOC_MAGIC, 5, int)
 #define SCULL_IOCGQSET 	_IOR(SCULL_IOC_MAGIC, 6, int)
 #define SCULL_IOCQQUANTUM 	_IO(SCULL_IOC_MAGIC, 7)
 #define SCULL_IOCQQSET		_IO(SCULL_IOC_MAGIC, 8)
 #define SCULL_IOCXQUANTUM	_IOWR(SCULL_IOC_MAGIC, 9, int)
 #define SCULL_IOCXQSET		_IOWR(SCULL_IOC_MAGIC, 10, int)
 #define SCULL_IOCHQUANTUM	_IO(SCULL_IOC_MAGIC, 11)
 #define SCULL_IOCHQSET		_IO(SCULL_IOC_MAGIC, 12)
 #define SCULL_P_IOCTSIZE	_IO(SCULL_IOC_MAGIC, 13)
 #define SCULL_P_IOCQSIZE	_IO(SCULL_IOC_MAGIC, 14)
 #define SCULL_IOC_MAXNR 	14

#endif /* _SCULL_H_ */
