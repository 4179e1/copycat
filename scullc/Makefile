DEBUG=y

ifeq ($(DEBUG),y)
	DEBUGFLAGS = -O -g -DSCULL_DEBUG
else
	DEBUGFLAGS = -O2
endif

EXTRA_CFLAGS += $(DEBUGFLAGS) -I$(LDDINC) -Wall

ifneq ($(KERNELRELEASE),)
scull-objs := main.o pipe.o
obj-m := scull.o
else
KERNELDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

modules:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) LDDINC=$(PWD)/../include modules
endif 

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .*.swp *.ko.* modules.order Module.symvers .tmp_versions
