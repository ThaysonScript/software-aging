import matplotlib.pyplot as plt
import pandas as pd
from sklearn.linear_model import LinearRegression
from pathlib import Path
import shutil

base_dir = "C:/Users/pedro/WebstormProjects/software-aging/containers-aging/plot/data"

class Plot:
    def __init__(self):
        self.plotted = 0

    def plot(
            self,
            folder,
            filename,
            ylabel,
            datetime="date_time",
            title=None, separator=';',
            decimal_separator=",",
            division=1,
            includeColYlabel=False,
            cols_to_divide=[]
    ):
        try:
            df = pd.read_csv(
                folder.joinpath(filename),
                sep=separator,
                decimal=decimal_separator,
                dayfirst=False,
                parse_dates=[datetime]).rename(columns={datetime: 'seconds'})
        except (FileNotFoundError):
            return

        self.plotted += 1

        df['seconds'] = (df['seconds'] - df['seconds'][0]).dt.total_seconds() / 3600
        df = df.set_index('seconds').replace(',', '.', regex=True).apply(lambda x: pd.to_numeric(x))
        cols_to_divide = cols_to_divide if len(cols_to_divide) != 0 else df.columns
        df[cols_to_divide] = df[cols_to_divide].div(division)

        for col in df.columns:
            col_mix = col + " " + ylabel if type(ylabel) is str and includeColYlabel else ylabel

            df[col] = df[col].fillna(0)

            x = df.index.to_numpy().reshape((-1, 1))
            y = df[col].to_numpy().reshape((-1, 1))

            model = LinearRegression()
            model.fit(x, y)

            Y_pred = model.predict(x)

            ax = df.plot(
                y=col,
                legend=0,
                xlabel='Time(h)',
                ylabel=col_mix if type(ylabel) is str else ylabel[col] if type(
                    ylabel) is dict and col in ylabel else col,
                title=title if type(title) is str else title[col] if type(title) is dict and col in title else col,
                figsize=(10, 5),
                style='k',
            )

            # Adicionar a linha da regressão
            ax.plot(x, Y_pred, color='red')
            fig = ax.get_figure()
            fig.savefig(folder.joinpath('plots_img').joinpath(f"{title}-{col}.png"))
            plt.close('all')


def start(base_folder, qtd_item):
    plots_folder = base_folder.joinpath('plots_img')
    if not plots_folder.exists():
        plots_folder.mkdir()
    shutil.rmtree(plots_folder)
    plots_folder.mkdir()

    plot_obj = Plot()

    plot_obj.plot(
        title="CPU",
        folder=base_folder,
        filename='cpu.csv',
        ylabel='(percentage)',
        includeColYlabel=True
    )

    plot_obj.plot(
        title="Disk",
        folder=base_folder,
        filename='disk.csv',
        ylabel='Disk usage (GB)',
        division=1048576
    )

    plot_obj.plot(
        title="Zumbis",
        folder=base_folder,
        filename='process.csv',
        ylabel='Zumbis processes(qtt)'
    )

    plot_obj.plot(
        title="Memory",
        folder=base_folder,
        filename='memory.csv',
        ylabel='(MB)',
        division=1024,
        includeColYlabel=True
    )

    plot_obj.plot(
        title="Process - Docker",
        folder=base_folder,
        filename='docker.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - Dockerd",
        folder=base_folder,
        filename='dockerd.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - Containerd",
        folder=base_folder,
        filename='containerd.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - Containerd-shim",
        folder=base_folder,
        filename='containerd-shim.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - docker-proxy",
        folder=base_folder,
        filename='docker-proxy.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - runc",
        folder=base_folder,
        filename='runc.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    # ------------------------------------------------- IMAGES --------------------------------------------
    plot_obj.plot(
        title="Teastore - Java",
        folder=base_folder,
        filename='java.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Rabbitmq - beam.smp",
        folder=base_folder,
        filename='beam.smp.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Teastore - mysqld",
        folder=base_folder,
        filename='mysqld.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    # ------------------------------------------------- PODMAN --------------------------------------------
    plot_obj.plot(
        title="Process - Podman",
        folder=base_folder,
        filename='podman.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - Conmon",
        folder=base_folder,
        filename='conmon.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - Crun",
        folder=base_folder,
        filename='crun.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Process - systemd",
        folder=base_folder,
        filename='systemd.csv',
        ylabel={'cpu': 'CPU usage (percentage)', "rss": "Physical memory usage(MB)",
                "vsz": "Virtual memory usage (MB)", "swap": "Swap used(MB)", 'mem': 'Memory usage (percentage)'},
        includeColYlabel=True,
        cols_to_divide=['rss', 'vsz', 'swap'],
        division=1024
    )

    plot_obj.plot(
        title="Server response time",
        folder=base_folder,
        filename='response_times.csv',
        ylabel='Response time(s)',
        division=1000
    )

    print(f"Ploted {plot_obj.plotted}/{qtd_item -1} ")


if __name__ == "__main__":
    for item in Path(base_dir).iterdir():
        if item.is_dir():
            csv_files = [file for file in item.iterdir() if file.suffix == '.csv']
            qtd_item = len(csv_files)

            print(f"Entering folder {item.name}")
            start(item, qtd_item)
