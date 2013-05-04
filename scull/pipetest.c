#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>

int main (int argc, char **argv)
{
	char buffer[4096];
	int delay = 1, n, m = 0;
	int fd = 0;
	if (argc > 1)
		fd = open (argv[1], O_RDONLY);
	fcntl (fd, F_SETFL, fcntl (fd, F_GETFL) | O_NONBLOCK);
	fcntl (1, F_SETFL, fcntl (1, F_GETFL) | O_NONBLOCK);

	while (1)
	{
		n = read (fd, buffer, 4000);
		if (n >= 0)
			m = write (1, buffer, n);
		if ((n < 0 || m < 0) && (errno != EAGAIN))
			break;
		sleep (delay);
	}
	perror (n < 0 ? "stdin" : "stdout");
	exit (1);
}
