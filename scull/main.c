#include <linux/module.h>
#include "scull.h"

MODULE_LICENSE ("GPL");

int scull_init_module (void)
{
	PDEBUG ("hello world!\n");
	return 0;
}

void scull_cleanup_module (void)
{
	PDEBUG ("goodby cruial world!\n");
}

module_init (scull_init_module);
module_exit (scull_cleanup_module);
