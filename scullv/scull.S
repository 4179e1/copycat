
scull.ko:     file format elf64-x86-64

Disassembly of section .text:

0000000000000000 <scull_llseek>:
	up (&dev->sem);
	return retval;
}

loff_t scull_llseek (struct file *filp, loff_t off, int whence)
   0:	55                   	push   %rbp
   1:	48 89 e5             	mov    %rsp,%rbp
   4:	e8 00 00 00 00       	callq  9 <scull_llseek+0x9>
{
	return 0;
   9:	b8 00 00 00 00       	mov    $0x0,%eax
   e:	c9                   	leaveq 
   f:	c3                   	retq   

0000000000000010 <scull_ioctl>:
}

long scull_ioctl (struct file *filp, unsigned int cmd, unsigned long arg)
  10:	55                   	push   %rbp
  11:	48 89 e5             	mov    %rsp,%rbp
  14:	e8 00 00 00 00       	callq  19 <scull_ioctl+0x9>
{
	return 0;
  19:	b8 00 00 00 00       	mov    $0x0,%eax
  1e:	c9                   	leaveq 
  1f:	c3                   	retq   

0000000000000020 <scull_release>:
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
  20:	55                   	push   %rbp
  21:	48 89 e5             	mov    %rsp,%rbp
  24:	e8 00 00 00 00       	callq  29 <scull_release+0x9>
{
	return 0;
  29:	b8 00 00 00 00       	mov    $0x0,%eax
  2e:	c9                   	leaveq 
  2f:	c3                   	retq   

0000000000000030 <scull_trim>:
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
  30:	55                   	push   %rbp
  31:	48 89 e5             	mov    %rsp,%rbp
  34:	41 57                	push   %r15
  36:	41 56                	push   %r14
  38:	41 55                	push   %r13
  3a:	41 54                	push   %r12
  3c:	53                   	push   %rbx
  3d:	48 83 ec 08          	sub    $0x8,%rsp
  41:	e8 00 00 00 00       	callq  46 <scull_trim+0x16>
  46:	49 89 ff             	mov    %rdi,%r15
{
	struct scull_qset *next, *dptr;
  49:	44 8b 77 0c          	mov    0xc(%rdi),%r14d
	int qset = dev->qset;
	int i;

  4d:	4c 8b 2f             	mov    (%rdi),%r13
  50:	4d 85 ed             	test   %r13,%r13
  53:	74 56                	je     ab <scull_trim+0x7b>
	for (dptr = dev->data; dptr; dptr = next)
	{
  55:	49 83 7d 00 00       	cmpq   $0x0,0x0(%r13)
  5a:	74 3b                	je     97 <scull_trim+0x67>
		if (dptr->data)
		{
  5c:	45 85 f6             	test   %r14d,%r14d
  5f:	7e 25                	jle    86 <scull_trim+0x56>
  61:	41 bc 00 00 00 00    	mov    $0x0,%r12d
  67:	bb 00 00 00 00       	mov    $0x0,%ebx
			for (i = 0; i < qset; i++)
  6c:	49 8b 45 00          	mov    0x0(%r13),%rax
  70:	48 8b 3c 18          	mov    (%rax,%rbx,1),%rdi
  74:	e8 00 00 00 00       	callq  79 <scull_trim+0x49>
  79:	41 83 c4 01          	add    $0x1,%r12d
  7d:	48 83 c3 08          	add    $0x8,%rbx
  81:	45 39 f4             	cmp    %r14d,%r12d
  84:	75 e6                	jne    6c <scull_trim+0x3c>
				kfree (dptr->data[i]); /* kfree(NULL) is OK */
  86:	49 8b 7d 00          	mov    0x0(%r13),%rdi
  8a:	e8 00 00 00 00       	callq  8f <scull_trim+0x5f>
			kfree (dptr->data);
  8f:	49 c7 45 00 00 00 00 	movq   $0x0,0x0(%r13)
  96:	00 
			dptr->data = NULL;
		}
  97:	49 8b 5d 08          	mov    0x8(%r13),%rbx
		next = dptr->next;
  9b:	4c 89 ef             	mov    %r13,%rdi
  9e:	e8 00 00 00 00       	callq  a3 <scull_trim+0x73>
  a3:	49 89 dd             	mov    %rbx,%r13
  a6:	48 85 db             	test   %rbx,%rbx
  a9:	75 aa                	jne    55 <scull_trim+0x25>
		kfree (dptr);
	}
  ab:	49 c7 47 10 00 00 00 	movq   $0x0,0x10(%r15)
  b2:	00 
	dev->size = 0;
  b3:	8b 05 00 00 00 00    	mov    0(%rip),%eax        # b9 <scull_trim+0x89>
  b9:	41 89 47 08          	mov    %eax,0x8(%r15)
	dev->quantum = scull_quantum;
  bd:	8b 05 00 00 00 00    	mov    0(%rip),%eax        # c3 <scull_trim+0x93>
  c3:	41 89 47 0c          	mov    %eax,0xc(%r15)
	dev->qset = scull_qset;
  c7:	49 c7 07 00 00 00 00 	movq   $0x0,(%r15)
	dev->data = NULL;
	return 0;
	return 0;
  ce:	b8 00 00 00 00       	mov    $0x0,%eax
  d3:	48 83 c4 08          	add    $0x8,%rsp
  d7:	5b                   	pop    %rbx
  d8:	41 5c                	pop    %r12
  da:	41 5d                	pop    %r13
  dc:	41 5e                	pop    %r14
  de:	41 5f                	pop    %r15
  e0:	c9                   	leaveq 
  e1:	c3                   	retq   

00000000000000e2 <cleanup_module>:
}

void scull_cleanup_module (void)
  e2:	55                   	push   %rbp
  e3:	48 89 e5             	mov    %rsp,%rbp
  e6:	41 56                	push   %r14
  e8:	41 55                	push   %r13
  ea:	41 54                	push   %r12
  ec:	53                   	push   %rbx
  ed:	e8 00 00 00 00       	callq  f2 <cleanup_module+0x10>
{
	int i;
  f2:	44 8b 35 00 00 00 00 	mov    0(%rip),%r14d        # f9 <cleanup_module+0x17>
  f9:	44 8b 2d 00 00 00 00 	mov    0(%rip),%r13d        # 100 <cleanup_module+0x1e>
	dev_t devno = MKDEV (scull_major, scull_minor);

 100:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
 107:	b8 00 00 00 00       	mov    $0x0,%eax
 10c:	e8 00 00 00 00       	callq  111 <cleanup_module+0x2f>
	PDEBUG ("goodbye cruial world!\n");
	
 111:	48 83 3d 00 00 00 00 	cmpq   $0x0,0(%rip)        # 119 <cleanup_module+0x37>
 118:	00 
 119:	74 56                	je     171 <cleanup_module+0x8f>
	if (scull_devices)
	{
 11b:	83 3d 00 00 00 00 00 	cmpl   $0x0,0(%rip)        # 122 <cleanup_module+0x40>
 122:	7e 41                	jle    165 <cleanup_module+0x83>
 124:	41 bc 00 00 00 00    	mov    $0x0,%r12d
 12a:	bb 00 00 00 00       	mov    $0x0,%ebx
		for (i = 0; i < scull_nr_devs; i++)
		{
 12f:	48 89 df             	mov    %rbx,%rdi
 132:	48 03 3d 00 00 00 00 	add    0(%rip),%rdi        # 139 <cleanup_module+0x57>
 139:	e8 00 00 00 00       	callq  13e <cleanup_module+0x5c>
			scull_trim (&scull_devices[i]);
 13e:	48 89 df             	mov    %rbx,%rdi
 141:	48 03 3d 00 00 00 00 	add    0(%rip),%rdi        # 148 <cleanup_module+0x66>
 148:	48 83 c7 38          	add    $0x38,%rdi
 14c:	e8 00 00 00 00       	callq  151 <cleanup_module+0x6f>
 151:	41 83 c4 01          	add    $0x1,%r12d
 155:	48 81 c3 a0 00 00 00 	add    $0xa0,%rbx
 15c:	44 39 25 00 00 00 00 	cmp    %r12d,0(%rip)        # 163 <cleanup_module+0x81>
 163:	7f ca                	jg     12f <cleanup_module+0x4d>
			cdev_del (&scull_devices[i].cdev);
		}
 165:	48 8b 3d 00 00 00 00 	mov    0(%rip),%rdi        # 16c <cleanup_module+0x8a>
 16c:	e8 00 00 00 00       	callq  171 <cleanup_module+0x8f>
		kfree (scull_devices);
	}

 171:	8b 35 00 00 00 00    	mov    0(%rip),%esi        # 177 <cleanup_module+0x95>
 177:	44 89 f7             	mov    %r14d,%edi
 17a:	c1 e7 14             	shl    $0x14,%edi
 17d:	44 09 ef             	or     %r13d,%edi
 180:	e8 00 00 00 00       	callq  185 <cleanup_module+0xa3>
	unregister_chrdev_region (devno, scull_nr_devs);
 185:	5b                   	pop    %rbx
 186:	41 5c                	pop    %r12
 188:	41 5d                	pop    %r13
 18a:	41 5e                	pop    %r14
 18c:	c9                   	leaveq 
 18d:	c3                   	retq   

000000000000018e <scull_open>:
 18e:	55                   	push   %rbp
 18f:	48 89 e5             	mov    %rsp,%rbp
 192:	48 83 ec 10          	sub    $0x10,%rsp
 196:	48 89 1c 24          	mov    %rbx,(%rsp)
 19a:	4c 89 64 24 08       	mov    %r12,0x8(%rsp)
 19f:	e8 00 00 00 00       	callq  1a4 <scull_open+0x16>
 1a4:	48 8b 9f f0 01 00 00 	mov    0x1f0(%rdi),%rbx
 1ab:	48 83 eb 38          	sub    $0x38,%rbx
 1af:	48 89 9e a0 00 00 00 	mov    %rbx,0xa0(%rsi)
 1b6:	8b 46 38             	mov    0x38(%rsi),%eax
 1b9:	83 e0 03             	and    $0x3,%eax
 1bc:	ba 00 00 00 00       	mov    $0x0,%edx
 1c1:	83 f8 01             	cmp    $0x1,%eax
 1c4:	75 2a                	jne    1f0 <scull_open+0x62>
 1c6:	4c 8d 63 20          	lea    0x20(%rbx),%r12
 1ca:	4c 89 e7             	mov    %r12,%rdi
 1cd:	e8 00 00 00 00       	callq  1d2 <scull_open+0x44>
 1d2:	ba 00 fe ff ff       	mov    $0xfffffe00,%edx
 1d7:	85 c0                	test   %eax,%eax
 1d9:	75 15                	jne    1f0 <scull_open+0x62>
 1db:	48 89 df             	mov    %rbx,%rdi
 1de:	e8 00 00 00 00       	callq  1e3 <scull_open+0x55>
 1e3:	4c 89 e7             	mov    %r12,%rdi
 1e6:	e8 00 00 00 00       	callq  1eb <scull_open+0x5d>
 1eb:	ba 00 00 00 00       	mov    $0x0,%edx
 1f0:	89 d0                	mov    %edx,%eax
 1f2:	48 8b 1c 24          	mov    (%rsp),%rbx
 1f6:	4c 8b 64 24 08       	mov    0x8(%rsp),%r12
 1fb:	c9                   	leaveq 
 1fc:	c3                   	retq   

00000000000001fd <scull_follow>:
 1fd:	55                   	push   %rbp
 1fe:	48 89 e5             	mov    %rsp,%rbp
 201:	41 57                	push   %r15
 203:	41 56                	push   %r14
 205:	41 55                	push   %r13
 207:	41 54                	push   %r12
 209:	53                   	push   %rbx
 20a:	48 83 ec 18          	sub    $0x18,%rsp
 20e:	e8 00 00 00 00       	callq  213 <scull_follow+0x16>
 213:	49 89 fd             	mov    %rdi,%r13
 216:	41 89 f6             	mov    %esi,%r14d
 219:	4c 8b 27             	mov    (%rdi),%r12
 21c:	4d 85 e4             	test   %r12,%r12
 21f:	75 7e                	jne    29f <scull_follow+0xa2>
		if (flags & GFP_DMA)
			cachep = malloc_sizes[i].cs_dmacachep;
		else
#endif
			cachep = malloc_sizes[i].cs_cachep;
 221:	48 8b 1d 00 00 00 00 	mov    0(%rip),%rbx        # 228 <scull_follow+0x2b>

		ret = kmem_cache_alloc_notrace(cachep, flags);
 228:	be d0 00 00 00       	mov    $0xd0,%esi
 22d:	48 89 df             	mov    %rbx,%rdi
 230:	e8 00 00 00 00       	callq  235 <scull_follow+0x38>
 235:	49 89 c4             	mov    %rax,%r12

		trace_kmalloc(_THIS_IP_, ret,
 238:	48 89 df             	mov    %rbx,%rdi
 23b:	e8 00 00 00 00       	callq  240 <scull_follow+0x43>
 240:	48 89 45 c0          	mov    %rax,0xffffffffffffffc0(%rbp)
 244:	4d 89 e7             	mov    %r12,%r15
	{(unsigned long)__GFP_RECLAIMABLE,	"GFP_RECLAIMABLE"},	\
	{(unsigned long)__GFP_MOVABLE,		"GFP_MOVABLE"}		\
	) : "GFP_NOWAIT"

TRACE_EVENT(kmalloc,
 247:	83 3d 00 00 00 00 00 	cmpl   $0x0,0(%rip)        # 24e <scull_follow+0x51>
 24e:	74 31                	je     281 <scull_follow+0x84>
 250:	48 8b 1d 00 00 00 00 	mov    0(%rip),%rbx        # 257 <scull_follow+0x5a>
 257:	48 85 db             	test   %rbx,%rbx
 25a:	74 25                	je     281 <scull_follow+0x84>
 25c:	41 b8 d0 00 00 00    	mov    $0xd0,%r8d
 262:	48 8b 4d c0          	mov    0xffffffffffffffc0(%rbp),%rcx
 266:	ba 10 00 00 00       	mov    $0x10,%edx
 26b:	4c 89 fe             	mov    %r15,%rsi
 26e:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
 275:	ff 13                	callq  *(%rbx)
 277:	48 83 c3 08          	add    $0x8,%rbx
 27b:	48 83 3b 00          	cmpq   $0x0,(%rbx)
 27f:	75 db                	jne    25c <scull_follow+0x5f>
 281:	4d 89 65 00          	mov    %r12,0x0(%r13)
 285:	4d 85 e4             	test   %r12,%r12
 288:	0f 84 ce 00 00 00    	je     35c <scull_follow+0x15f>
 28e:	49 c7 04 24 00 00 00 	movq   $0x0,(%r12)
 295:	00 
 296:	49 c7 44 24 08 00 00 	movq   $0x0,0x8(%r12)
 29d:	00 00 
 29f:	45 85 f6             	test   %r14d,%r14d
 2a2:	0f 84 b4 00 00 00    	je     35c <scull_follow+0x15f>
 2a8:	41 bd 00 00 00 00    	mov    $0x0,%r13d
 2ae:	49 83 7c 24 08 00    	cmpq   $0x0,0x8(%r12)
 2b4:	0f 85 90 00 00 00    	jne    34a <scull_follow+0x14d>
		if (flags & GFP_DMA)
			cachep = malloc_sizes[i].cs_dmacachep;
		else
#endif
			cachep = malloc_sizes[i].cs_cachep;
 2ba:	48 8b 1d 00 00 00 00 	mov    0(%rip),%rbx        # 2c1 <scull_follow+0xc4>

		ret = kmem_cache_alloc_notrace(cachep, flags);
 2c1:	be d0 00 00 00       	mov    $0xd0,%esi
 2c6:	48 89 df             	mov    %rbx,%rdi
 2c9:	e8 00 00 00 00       	callq  2ce <scull_follow+0xd1>
 2ce:	49 89 c7             	mov    %rax,%r15

		trace_kmalloc(_THIS_IP_, ret,
 2d1:	48 89 df             	mov    %rbx,%rdi
 2d4:	e8 00 00 00 00       	callq  2d9 <scull_follow+0xdc>
 2d9:	48 89 45 d0          	mov    %rax,0xffffffffffffffd0(%rbp)
 2dd:	4c 89 fb             	mov    %r15,%rbx
	{(unsigned long)__GFP_RECLAIMABLE,	"GFP_RECLAIMABLE"},	\
	{(unsigned long)__GFP_MOVABLE,		"GFP_MOVABLE"}		\
	) : "GFP_NOWAIT"

TRACE_EVENT(kmalloc,
 2e0:	83 3d 00 00 00 00 00 	cmpl   $0x0,0(%rip)        # 2e7 <scull_follow+0xea>
 2e7:	74 3e                	je     327 <scull_follow+0x12a>
 2e9:	48 8b 05 00 00 00 00 	mov    0(%rip),%rax        # 2f0 <scull_follow+0xf3>
 2f0:	48 89 45 c8          	mov    %rax,0xffffffffffffffc8(%rbp)
 2f4:	48 85 c0             	test   %rax,%rax
 2f7:	74 2e                	je     327 <scull_follow+0x12a>
 2f9:	41 b8 d0 00 00 00    	mov    $0xd0,%r8d
 2ff:	48 8b 4d d0          	mov    0xffffffffffffffd0(%rbp),%rcx
 303:	ba 10 00 00 00       	mov    $0x10,%edx
 308:	48 89 de             	mov    %rbx,%rsi
 30b:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
 312:	48 8b 45 c8          	mov    0xffffffffffffffc8(%rbp),%rax
 316:	ff 10                	callq  *(%rax)
 318:	48 83 45 c8 08       	addq   $0x8,0xffffffffffffffc8(%rbp)
 31d:	48 8b 45 c8          	mov    0xffffffffffffffc8(%rbp),%rax
 321:	48 83 38 00          	cmpq   $0x0,(%rax)
 325:	75 d2                	jne    2f9 <scull_follow+0xfc>
 327:	4d 89 7c 24 08       	mov    %r15,0x8(%r12)
 32c:	4d 85 ff             	test   %r15,%r15
 32f:	75 08                	jne    339 <scull_follow+0x13c>
 331:	41 bc 00 00 00 00    	mov    $0x0,%r12d
 337:	eb 23                	jmp    35c <scull_follow+0x15f>
 339:	49 c7 04 24 00 00 00 	movq   $0x0,(%r12)
 340:	00 
 341:	49 c7 44 24 08 00 00 	movq   $0x0,0x8(%r12)
 348:	00 00 
 34a:	4d 8b 64 24 08       	mov    0x8(%r12),%r12
 34f:	41 83 c5 01          	add    $0x1,%r13d
 353:	45 39 f5             	cmp    %r14d,%r13d
 356:	0f 85 52 ff ff ff    	jne    2ae <scull_follow+0xb1>
 35c:	4c 89 e0             	mov    %r12,%rax
 35f:	48 83 c4 18          	add    $0x18,%rsp
 363:	5b                   	pop    %rbx
 364:	41 5c                	pop    %r12
 366:	41 5d                	pop    %r13
 368:	41 5e                	pop    %r14
 36a:	41 5f                	pop    %r15
 36c:	c9                   	leaveq 
 36d:	c3                   	retq   

000000000000036e <scull_write>:
 36e:	55                   	push   %rbp
 36f:	48 89 e5             	mov    %rsp,%rbp
 372:	48 83 ec 50          	sub    $0x50,%rsp
 376:	48 89 5d d8          	mov    %rbx,0xffffffffffffffd8(%rbp)
 37a:	4c 89 65 e0          	mov    %r12,0xffffffffffffffe0(%rbp)
 37e:	4c 89 6d e8          	mov    %r13,0xffffffffffffffe8(%rbp)
 382:	4c 89 75 f0          	mov    %r14,0xfffffffffffffff0(%rbp)
 386:	4c 89 7d f8          	mov    %r15,0xfffffffffffffff8(%rbp)
 38a:	e8 00 00 00 00       	callq  38f <scull_write+0x21>
 38f:	48 89 75 c8          	mov    %rsi,0xffffffffffffffc8(%rbp)
 393:	48 89 55 c0          	mov    %rdx,0xffffffffffffffc0(%rbp)
 397:	48 89 4d b8          	mov    %rcx,0xffffffffffffffb8(%rbp)
 39b:	4c 8b af a0 00 00 00 	mov    0xa0(%rdi),%r13
 3a2:	45 8b 65 08          	mov    0x8(%r13),%r12d
 3a6:	41 8b 5d 0c          	mov    0xc(%r13),%ebx
 3aa:	49 8d 7d 20          	lea    0x20(%r13),%rdi
 3ae:	e8 00 00 00 00       	callq  3b3 <scull_write+0x45>
 3b3:	49 c7 c6 00 fe ff ff 	mov    $0xfffffffffffffe00,%r14
 3ba:	85 c0                	test   %eax,%eax
 3bc:	0f 85 e2 00 00 00    	jne    4a4 <scull_write+0x136>
 3c2:	48 8b 45 b8          	mov    0xffffffffffffffb8(%rbp),%rax
 3c6:	48 8b 30             	mov    (%rax),%rsi
 3c9:	89 d8                	mov    %ebx,%eax
 3cb:	41 0f af c4          	imul   %r12d,%eax
 3cf:	48 98                	cltq   
 3d1:	48 89 f2             	mov    %rsi,%rdx
 3d4:	48 89 c1             	mov    %rax,%rcx
 3d7:	48 89 f0             	mov    %rsi,%rax
 3da:	48 c1 fa 3f          	sar    $0x3f,%rdx
 3de:	48 f7 f9             	idiv   %rcx
 3e1:	48 89 d3             	mov    %rdx,%rbx
 3e4:	89 c6                	mov    %eax,%esi
 3e6:	4c 89 ef             	mov    %r13,%rdi
 3e9:	e8 00 00 00 00       	callq  3ee <scull_write+0x80>
 3ee:	49 89 c7             	mov    %rax,%r15
 3f1:	48 85 c0             	test   %rax,%rax
 3f4:	0f 84 9a 00 00 00    	je     494 <scull_write+0x126>
 3fa:	41 89 de             	mov    %ebx,%r14d
 3fd:	89 da                	mov    %ebx,%edx
 3ff:	89 d8                	mov    %ebx,%eax
 401:	c1 fa 1f             	sar    $0x1f,%edx
 404:	41 f7 fc             	idiv   %r12d
 407:	89 45 d4             	mov    %eax,0xffffffffffffffd4(%rbp)
 40a:	49 83 3f 00          	cmpq   $0x0,(%r15)
 40e:	75 20                	jne    430 <scull_write+0xc2>
 410:	48 63 d8             	movslq %eax,%rbx
 413:	48 c1 e3 03          	shl    $0x3,%rbx
			      size, slab_buffer_size(cachep), flags);

		return ret;
	}
	return __kmalloc(size, flags);
 417:	49 63 fc             	movslq %r12d,%rdi
 41a:	be d0 00 00 00       	mov    $0xd0,%esi
 41f:	e8 00 00 00 00       	callq  424 <scull_write+0xb6>
 424:	48 89 03             	mov    %rax,(%rbx)
 427:	49 03 1f             	add    (%r15),%rbx
 42a:	48 83 3b 00          	cmpq   $0x0,(%rbx)
 42e:	74 64                	je     494 <scull_write+0x126>
 430:	44 89 f2             	mov    %r14d,%edx
 433:	44 89 f0             	mov    %r14d,%eax
 436:	c1 fa 1f             	sar    $0x1f,%edx
 439:	41 f7 fc             	idiv   %r12d
 43c:	44 89 e0             	mov    %r12d,%eax
 43f:	29 d0                	sub    %edx,%eax
 441:	48 63 d8             	movslq %eax,%rbx
 444:	48 3b 5d c0          	cmp    0xffffffffffffffc0(%rbp),%rbx
 448:	48 0f 47 5d c0       	cmova  0xffffffffffffffc0(%rbp),%rbx
 44d:	48 63 45 d4          	movslq 0xffffffffffffffd4(%rbp),%rax
 451:	48 c1 e0 03          	shl    $0x3,%rax
 455:	49 03 07             	add    (%r15),%rax
 458:	48 63 d2             	movslq %edx,%rdx
 45b:	48 8b 38             	mov    (%rax),%rdi
 45e:	48 01 d7             	add    %rdx,%rdi
 461:	89 da                	mov    %ebx,%edx
 463:	48 8b 75 c8          	mov    0xffffffffffffffc8(%rbp),%rsi
 467:	e8 00 00 00 00       	callq  46c <scull_write+0xfe>
 46c:	49 c7 c6 f2 ff ff ff 	mov    $0xfffffffffffffff2,%r14
 473:	48 85 c0             	test   %rax,%rax
 476:	75 23                	jne    49b <scull_write+0x12d>
 478:	48 89 d8             	mov    %rbx,%rax
 47b:	48 8b 55 b8          	mov    0xffffffffffffffb8(%rbp),%rdx
 47f:	48 03 02             	add    (%rdx),%rax
 482:	48 89 02             	mov    %rax,(%rdx)
 485:	49 89 de             	mov    %rbx,%r14
 488:	49 39 45 10          	cmp    %rax,0x10(%r13)
 48c:	73 0d                	jae    49b <scull_write+0x12d>
 48e:	49 89 45 10          	mov    %rax,0x10(%r13)
 492:	eb 07                	jmp    49b <scull_write+0x12d>
 494:	49 c7 c6 f4 ff ff ff 	mov    $0xfffffffffffffff4,%r14
 49b:	49 8d 7d 20          	lea    0x20(%r13),%rdi
 49f:	e8 00 00 00 00       	callq  4a4 <scull_write+0x136>
 4a4:	4c 89 f0             	mov    %r14,%rax
 4a7:	48 8b 5d d8          	mov    0xffffffffffffffd8(%rbp),%rbx
 4ab:	4c 8b 65 e0          	mov    0xffffffffffffffe0(%rbp),%r12
 4af:	4c 8b 6d e8          	mov    0xffffffffffffffe8(%rbp),%r13
 4b3:	4c 8b 75 f0          	mov    0xfffffffffffffff0(%rbp),%r14
 4b7:	4c 8b 7d f8          	mov    0xfffffffffffffff8(%rbp),%r15
 4bb:	c9                   	leaveq 
 4bc:	c3                   	retq   

00000000000004bd <scull_read>:
 4bd:	55                   	push   %rbp
 4be:	48 89 e5             	mov    %rsp,%rbp
 4c1:	48 83 ec 40          	sub    $0x40,%rsp
 4c5:	48 89 5d d8          	mov    %rbx,0xffffffffffffffd8(%rbp)
 4c9:	4c 89 65 e0          	mov    %r12,0xffffffffffffffe0(%rbp)
 4cd:	4c 89 6d e8          	mov    %r13,0xffffffffffffffe8(%rbp)
 4d1:	4c 89 75 f0          	mov    %r14,0xfffffffffffffff0(%rbp)
 4d5:	4c 89 7d f8          	mov    %r15,0xfffffffffffffff8(%rbp)
 4d9:	e8 00 00 00 00       	callq  4de <scull_read+0x21>
 4de:	48 89 75 c8          	mov    %rsi,0xffffffffffffffc8(%rbp)
 4e2:	49 89 d6             	mov    %rdx,%r14
 4e5:	48 89 4d c0          	mov    %rcx,0xffffffffffffffc0(%rbp)
 4e9:	48 8b 9f a0 00 00 00 	mov    0xa0(%rdi),%rbx
 4f0:	44 8b 6b 08          	mov    0x8(%rbx),%r13d
 4f4:	44 8b 7b 0c          	mov    0xc(%rbx),%r15d
 4f8:	48 8d 43 20          	lea    0x20(%rbx),%rax
 4fc:	48 89 45 d0          	mov    %rax,0xffffffffffffffd0(%rbp)
 500:	48 89 c7             	mov    %rax,%rdi
 503:	e8 00 00 00 00       	callq  508 <scull_read+0x4b>
 508:	49 c7 c4 00 fe ff ff 	mov    $0xfffffffffffffe00,%r12
 50f:	85 c0                	test   %eax,%eax
 511:	0f 85 bb 00 00 00    	jne    5d2 <scull_read+0x115>
 517:	48 8b 55 c0          	mov    0xffffffffffffffc0(%rbp),%rdx
 51b:	48 8b 32             	mov    (%rdx),%rsi
 51e:	48 8b 4b 10          	mov    0x10(%rbx),%rcx
 522:	48 39 ce             	cmp    %rcx,%rsi
 525:	0f 83 98 00 00 00    	jae    5c3 <scull_read+0x106>
 52b:	4a 8d 04 36          	lea    (%rsi,%r14,1),%rax
 52f:	48 89 ca             	mov    %rcx,%rdx
 532:	48 29 f2             	sub    %rsi,%rdx
 535:	48 39 c1             	cmp    %rax,%rcx
 538:	4c 0f 42 f2          	cmovb  %rdx,%r14
 53c:	44 89 f8             	mov    %r15d,%eax
 53f:	41 0f af c5          	imul   %r13d,%eax
 543:	48 98                	cltq   
 545:	48 89 f2             	mov    %rsi,%rdx
 548:	48 89 c1             	mov    %rax,%rcx
 54b:	48 89 f0             	mov    %rsi,%rax
 54e:	48 c1 fa 3f          	sar    $0x3f,%rdx
 552:	48 f7 f9             	idiv   %rcx
 555:	49 89 d4             	mov    %rdx,%r12
 558:	89 c6                	mov    %eax,%esi
 55a:	48 89 df             	mov    %rbx,%rdi
 55d:	e8 00 00 00 00       	callq  562 <scull_read+0xa5>
 562:	48 85 c0             	test   %rax,%rax
 565:	74 5c                	je     5c3 <scull_read+0x106>
 567:	48 8b 30             	mov    (%rax),%rsi
 56a:	48 85 f6             	test   %rsi,%rsi
 56d:	74 54                	je     5c3 <scull_read+0x106>
 56f:	44 89 e2             	mov    %r12d,%edx
 572:	44 89 e0             	mov    %r12d,%eax
 575:	c1 fa 1f             	sar    $0x1f,%edx
 578:	41 f7 fd             	idiv   %r13d
 57b:	89 d1                	mov    %edx,%ecx
 57d:	48 98                	cltq   
 57f:	48 8b 14 c6          	mov    (%rsi,%rax,8),%rdx
 583:	48 85 d2             	test   %rdx,%rdx
 586:	74 3b                	je     5c3 <scull_read+0x106>
 588:	44 89 e8             	mov    %r13d,%eax
 58b:	29 c8                	sub    %ecx,%eax
 58d:	48 98                	cltq   
 58f:	49 39 c6             	cmp    %rax,%r14
 592:	48 89 c3             	mov    %rax,%rbx
 595:	49 0f 46 de          	cmovbe %r14,%rbx
 599:	48 63 f1             	movslq %ecx,%rsi
 59c:	48 8d 34 32          	lea    (%rdx,%rsi,1),%rsi
 5a0:	89 da                	mov    %ebx,%edx
 5a2:	48 8b 7d c8          	mov    0xffffffffffffffc8(%rbp),%rdi
 5a6:	e8 00 00 00 00       	callq  5ab <scull_read+0xee>
 5ab:	49 c7 c4 f2 ff ff ff 	mov    $0xfffffffffffffff2,%r12
 5b2:	48 85 c0             	test   %rax,%rax
 5b5:	75 12                	jne    5c9 <scull_read+0x10c>
 5b7:	48 8b 4d c0          	mov    0xffffffffffffffc0(%rbp),%rcx
 5bb:	48 01 19             	add    %rbx,(%rcx)
 5be:	49 89 dc             	mov    %rbx,%r12
 5c1:	eb 06                	jmp    5c9 <scull_read+0x10c>
 5c3:	41 bc 00 00 00 00    	mov    $0x0,%r12d
 5c9:	48 8b 7d d0          	mov    0xffffffffffffffd0(%rbp),%rdi
 5cd:	e8 00 00 00 00       	callq  5d2 <scull_read+0x115>
 5d2:	4c 89 e0             	mov    %r12,%rax
 5d5:	48 8b 5d d8          	mov    0xffffffffffffffd8(%rbp),%rbx
 5d9:	4c 8b 65 e0          	mov    0xffffffffffffffe0(%rbp),%r12
 5dd:	4c 8b 6d e8          	mov    0xffffffffffffffe8(%rbp),%r13
 5e1:	4c 8b 75 f0          	mov    0xfffffffffffffff0(%rbp),%r14
 5e5:	4c 8b 7d f8          	mov    0xfffffffffffffff8(%rbp),%r15
 5e9:	c9                   	leaveq 
 5ea:	c3                   	retq   

00000000000005eb <init_module>:
}

int scull_init_module (void)
 5eb:	55                   	push   %rbp
 5ec:	48 89 e5             	mov    %rsp,%rbp
 5ef:	41 57                	push   %r15
 5f1:	41 56                	push   %r14
 5f3:	41 55                	push   %r13
 5f5:	41 54                	push   %r12
 5f7:	53                   	push   %rbx
 5f8:	48 83 ec 18          	sub    $0x18,%rsp
 5fc:	e8 00 00 00 00       	callq  601 <init_module+0x16>
{
	int result, i;
 601:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffffffffffd4(%rbp)
	dev_t dev = 0;

 608:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
 60f:	b8 00 00 00 00       	mov    $0x0,%eax
 614:	e8 00 00 00 00       	callq  619 <init_module+0x2e>
	PDEBUG ("hello world!\n");

 619:	8b 05 00 00 00 00    	mov    0(%rip),%eax        # 61f <init_module+0x34>
 61f:	85 c0                	test   %eax,%eax
 621:	74 24                	je     647 <init_module+0x5c>
	if (scull_major)
	{
 623:	89 c7                	mov    %eax,%edi
 625:	c1 e7 14             	shl    $0x14,%edi
 628:	0b 3d 00 00 00 00    	or     0(%rip),%edi        # 62e <init_module+0x43>
 62e:	89 7d d4             	mov    %edi,0xffffffffffffffd4(%rbp)
		dev = MKDEV (scull_major, scull_minor);
 631:	8b 35 00 00 00 00    	mov    0(%rip),%esi        # 637 <init_module+0x4c>
 637:	48 c7 c2 00 00 00 00 	mov    $0x0,%rdx
 63e:	e8 00 00 00 00       	callq  643 <init_module+0x58>
 643:	89 c3                	mov    %eax,%ebx
 645:	eb 2a                	jmp    671 <init_module+0x86>
		result = register_chrdev_region (dev, scull_nr_devs, "scull");
	}
	else
	{
 647:	8b 15 00 00 00 00    	mov    0(%rip),%edx        # 64d <init_module+0x62>
 64d:	8b 35 00 00 00 00    	mov    0(%rip),%esi        # 653 <init_module+0x68>
 653:	48 8d 7d d4          	lea    0xffffffffffffffd4(%rbp),%rdi
 657:	48 c7 c1 00 00 00 00 	mov    $0x0,%rcx
 65e:	e8 00 00 00 00       	callq  663 <init_module+0x78>
 663:	89 c3                	mov    %eax,%ebx
		result = alloc_chrdev_region (&dev, scull_minor, scull_nr_devs, "scull");
 665:	8b 45 d4             	mov    0xffffffffffffffd4(%rbp),%eax
 668:	c1 e8 14             	shr    $0x14,%eax
 66b:	89 05 00 00 00 00    	mov    %eax,0(%rip)        # 671 <init_module+0x86>
		scull_major = MAJOR(dev);
	}
 671:	85 db                	test   %ebx,%ebx
 673:	79 1c                	jns    691 <init_module+0xa6>
	if (result < 0) {
 675:	8b 35 00 00 00 00    	mov    0(%rip),%esi        # 67b <init_module+0x90>
 67b:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
 682:	b8 00 00 00 00       	mov    $0x0,%eax
 687:	e8 00 00 00 00       	callq  68c <init_module+0xa1>
 68c:	e9 3f 01 00 00       	jmpq   7d0 <init_module+0x1e5>
			      size, slab_buffer_size(cachep), flags);

		return ret;
	}
	return __kmalloc(size, flags);
 691:	48 63 3d 00 00 00 00 	movslq 0(%rip),%rdi        # 698 <init_module+0xad>
 698:	48 8d 3c bf          	lea    (%rdi,%rdi,4),%rdi
 69c:	48 c1 e7 05          	shl    $0x5,%rdi
 6a0:	be d0 00 00 00       	mov    $0xd0,%esi
 6a5:	e8 00 00 00 00       	callq  6aa <init_module+0xbf>
		printk (KERN_WARNING "scull: can't get major %d\n", scull_major);
		return result;
	}

 6aa:	48 89 05 00 00 00 00 	mov    %rax,0(%rip)        # 6b1 <init_module+0xc6>
	scull_devices = kmalloc (scull_nr_devs * sizeof (struct scull_dev), GFP_KERNEL);
 6b1:	48 85 c0             	test   %rax,%rax
 6b4:	0f 84 05 01 00 00    	je     7bf <init_module+0x1d4>
	if (scull_devices == NULL)
	{
		result = -ENOMEM;
		goto fail;
	}
 6ba:	48 63 15 00 00 00 00 	movslq 0(%rip),%rdx        # 6c1 <init_module+0xd6>
 6c1:	48 8d 14 92          	lea    (%rdx,%rdx,4),%rdx
 6c5:	48 c1 e2 05          	shl    $0x5,%rdx
 6c9:	be 00 00 00 00       	mov    $0x0,%esi
 6ce:	48 89 c7             	mov    %rax,%rdi
 6d1:	e8 00 00 00 00       	callq  6d6 <init_module+0xeb>
	memset (scull_devices, 0, scull_nr_devs * sizeof (struct scull_dev));

 6d6:	83 3d 00 00 00 00 00 	cmpl   $0x0,0(%rip)        # 6dd <init_module+0xf2>
 6dd:	0f 8e e8 00 00 00    	jle    7cb <init_module+0x1e0>
 6e3:	41 bf 00 00 00 00    	mov    $0x0,%r15d
 6e9:	41 be 00 00 00 00    	mov    $0x0,%r14d
	for (i = 0; i < scull_nr_devs; i++)
	{
 6ef:	4c 89 f2             	mov    %r14,%rdx
 6f2:	48 03 15 00 00 00 00 	add    0(%rip),%rdx        # 6f9 <init_module+0x10e>
 6f9:	8b 05 00 00 00 00    	mov    0(%rip),%eax        # 6ff <init_module+0x114>
 6ff:	89 42 08             	mov    %eax,0x8(%rdx)
		scull_devices[i].quantum = scull_quantum;
 702:	4c 89 f2             	mov    %r14,%rdx
 705:	48 03 15 00 00 00 00 	add    0(%rip),%rdx        # 70c <init_module+0x121>
 70c:	8b 05 00 00 00 00    	mov    0(%rip),%eax        # 712 <init_module+0x127>
 712:	89 42 0c             	mov    %eax,0xc(%rdx)
		scull_devices[i].qset = scull_qset;
 715:	4c 89 f0             	mov    %r14,%rax
 718:	48 03 05 00 00 00 00 	add    0(%rip),%rax        # 71f <init_module+0x134>
 71f:	48 8d 50 20          	lea    0x20(%rax),%rdx

static inline void sema_init(struct semaphore *sem, int val)
{
	static struct lock_class_key __key;
	*sem = (struct semaphore) __SEMAPHORE_INITIALIZER(*sem, val);
 723:	48 8d 48 28          	lea    0x28(%rax),%rcx
 727:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%rax)
 72e:	c7 42 04 01 00 00 00 	movl   $0x1,0x4(%rdx)
 735:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
 739:	48 89 4a 10          	mov    %rcx,0x10(%rdx)
		sema_init (&scull_devices[i].sem, 1);
 73d:	4d 89 f4             	mov    %r14,%r12
 740:	4c 03 25 00 00 00 00 	add    0(%rip),%r12        # 747 <init_module+0x15c>
 747:	44 89 fa             	mov    %r15d,%edx
 74a:	03 15 00 00 00 00    	add    0(%rip),%edx        # 750 <init_module+0x165>
 750:	8b 05 00 00 00 00    	mov    0(%rip),%eax        # 756 <init_module+0x16b>
 756:	c1 e0 14             	shl    $0x14,%eax
 759:	41 89 d5             	mov    %edx,%r13d
 75c:	41 09 c5             	or     %eax,%r13d
 75f:	49 8d 5c 24 38       	lea    0x38(%r12),%rbx
 764:	48 c7 c6 00 00 00 00 	mov    $0x0,%rsi
 76b:	48 89 df             	mov    %rbx,%rdi
 76e:	e8 00 00 00 00       	callq  773 <init_module+0x188>
 773:	49 c7 44 24 78 00 00 	movq   $0x0,0x78(%r12)
 77a:	00 00 
 77c:	ba 01 00 00 00       	mov    $0x1,%edx
 781:	44 89 ee             	mov    %r13d,%esi
 784:	48 89 df             	mov    %rbx,%rdi
 787:	e8 00 00 00 00       	callq  78c <init_module+0x1a1>
 78c:	85 c0                	test   %eax,%eax
 78e:	74 16                	je     7a6 <init_module+0x1bb>
 790:	44 89 fa             	mov    %r15d,%edx
 793:	89 c6                	mov    %eax,%esi
 795:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
 79c:	b8 00 00 00 00       	mov    $0x0,%eax
 7a1:	e8 00 00 00 00       	callq  7a6 <init_module+0x1bb>
 7a6:	41 83 c7 01          	add    $0x1,%r15d
 7aa:	49 81 c6 a0 00 00 00 	add    $0xa0,%r14
 7b1:	44 39 3d 00 00 00 00 	cmp    %r15d,0(%rip)        # 7b8 <init_module+0x1cd>
 7b8:	7e 11                	jle    7cb <init_module+0x1e0>
 7ba:	e9 30 ff ff ff       	jmpq   6ef <init_module+0x104>
		scull_setup_cdev (&scull_devices[i], i);
	}

	return 0;

fail:
 7bf:	e8 00 00 00 00       	callq  7c4 <init_module+0x1d9>
 7c4:	bb f4 ff ff ff       	mov    $0xfffffff4,%ebx
 7c9:	eb 05                	jmp    7d0 <init_module+0x1e5>
	scull_cleanup_module();
 7cb:	bb 00 00 00 00       	mov    $0x0,%ebx
	return result;
 7d0:	89 d8                	mov    %ebx,%eax
 7d2:	48 83 c4 18          	add    $0x18,%rsp
 7d6:	5b                   	pop    %rbx
 7d7:	41 5c                	pop    %r12
 7d9:	41 5d                	pop    %r13
 7db:	41 5e                	pop    %r14
 7dd:	41 5f                	pop    %r15
 7df:	c9                   	leaveq 
 7e0:	c3                   	retq   
 7e1:	90                   	nop    
 7e2:	90                   	nop    
 7e3:	90                   	nop    
