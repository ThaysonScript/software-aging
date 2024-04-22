import os
import subprocess
import time


def write_to_file(filename, header, content):
    with open(filename, "a+") as file:
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        if file_size == 0:
            file.write(f"{header}\n")
        file.write(f"{content}\n")


def execute_command(command, informative=False, continue_if_error=False, error_informative=True) -> str:
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()
    return_code = process.wait()

    if return_code != 0:
        if error_informative:
            print(f'ERROR: {error.decode("utf-8").strip()}\n COMMAND: ${command}')
        if not continue_if_error:
            exit(return_code)
    else:
        if informative:
            print(output.decode("utf-8").strip())

        return output.decode("utf-8").strip().replace("\n", "")


def get_time(command) -> int:
    start_time = time.perf_counter_ns()
    execute_command(command)
    end_time = time.perf_counter_ns()
    return end_time - start_time
