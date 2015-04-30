import logging
from sys import stdout

logger = logging.getLogger('general_utils')

def set_up_stdout_logging():
    logger.setLevel(logging.INFO)
    ch = logging.StreamHandler(stdout)
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

def subprocess_check_retries(args, max_time=600):
    sleep_time = 1
    logger.debug("Running command {0!s}.".format(args))
    while sleep_time < max_time:
        try:
            subprocess.check_call(args)
        except subprocess.CalledProcessError:
            logger.error("Subprocess call with args {0} failed. Sleeping {1}".format(str(args), str(sleep_time)))
            sleep(sleep_time)
            sleep_time *= 2
        else:
            break


