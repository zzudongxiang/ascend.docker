from glob import glob
import os, re, stat, shutil, argparse

PKG_NAME_LEN = 15
RESOURCE_PATH = "./resource/"

CONTAINER_IMAGES = "ubuntu:20.04"
CONTAINER_INSIDE_PATH = "/mnt/host"
CONTAINER_OUTSIDE_PATH = os.popen("echo ${HOME}").readline().strip() + "/container/"

URL_ANACONDA = "https://www.anaconda.com/download"
URL_MINDSPORE = "https://www.mindspore.cn/versions"
URL_TORCH_NPU = "https://gitee.com/ascend/pytorch/releases"
URL_TOOLKIT = "https://www.hiascend.com/developer/download/community/result?module=cann"


def __init_args__():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-n",
        "--name",
        default="unknow",
        help="The name prefix of the created docker container",
    )
    parser.add_argument(
        "-v",
        "--version",
        default="7.0.0",
        help="The CANN version to be installed in the docker container",
    )
    parser.add_argument(
        "--network",
        default="bridge",
        choices=["bridge", "host"],
        help="Network connection type of docker container",
    )
    parser.add_argument(
        "-p",
        "--port",
        default=223,
        type=int,
        help="The ssh port exposed by the docker container",
    )
    parser.add_argument(
        "--pkg_path",
        default=".",
        help="The path where the package will be installed",
    )
    args = parser.parse_args()
    return args


def __get_pkg__(package_name, package_path):
    pkg_list = glob(package_path, recursive=True)
    pkg_count = len(pkg_list)
    if pkg_count > 0:
        pkg_path = None
        if pkg_count == 1:
            pkg_path = pkg_list[0]
        else:
            print(f"More than one {package_name} was found, please select one:")
            for i in range(pkg_count):
                print(f"  [{i + 1}]:", pkg_list[i])
            pkg_index = -1
            while pkg_index < 0 or pkg_index >= pkg_count:
                str_index = input(f"Enter the index of the package [1-{pkg_count}]: ")
                pkg_index = int(str_index) - 1 if re.match(r"^\d+$", str_index) else -1
            pkg_path = pkg_list[pkg_index]
            print()
        print(package_name.ljust(PKG_NAME_LEN, " "), end="")
        print(f"found in {pkg_path}, will be installed.")
        return pkg_path
    else:
        print(package_name.ljust(PKG_NAME_LEN, " "), end="")
        print(f"not found, it will not be installed.")
        return None


def __init_pkgs__(args):
    pkgs = packages(args)
    arch = os.popen("arch").readline().strip()
    mpich_path = f"{args.pkg_path}/**/mpich-*.tar.gz"
    pkgs.mpich_pkg = __get_pkg__("mpich", mpich_path)
    conda_path = f"{args.pkg_path}/**/Anaconda3*{arch}*.sh"
    pkgs.conda_pkg = __get_pkg__("anaconda", conda_path)
    toolkit_path = f"{args.pkg_path}/**/Ascend-cann-toolkit*{args.version}*{arch}*.run"
    pkgs.toolkit_pkg = __get_pkg__("toolkit", toolkit_path)
    kernel_path = f"{args.pkg_path}/**/Ascend-cann-kernel*{args.version}*.run"
    pkgs.kernel_pkg = __get_pkg__("kernel", kernel_path)
    mindspore_path = f"{args.pkg_path}/**/mindspore*{arch}*.whl"
    pkgs.mindspore_pkg = __get_pkg__("mindspore", mindspore_path)
    torch_path = f"{args.pkg_path}/**/torch_npu*{arch}*.whl"
    pkgs.torch_pkg = __get_pkg__("torch_npu", torch_path)
    print("-" * 50)
    user_confirm = "NA" if pkgs.Check() else "N"
    print(f"docker container name: {pkgs.container_name}")
    while not re.match(r"^[y|n]$", user_confirm, re.IGNORECASE):
        user_confirm = input("Are you sure to initialize the docker container? [y/n]: ")
    user_confirm = user_confirm.lower()
    if user_confirm == "y":
        return pkgs
    else:
        print("The User has canceled or Missing some required packages.")
        exit()


def __generate_script__(template_path, args_dict, script_path=None):
    with open(template_path, "r+", encoding="utf-8") as file:
        lines = file.readlines()
    for i in range(len(lines)):
        line = lines[i]
        index = line.find("#")
        lines[i] = line[:index] if index >= 0 else line
        lines[i] = lines[i].strip().strip("\\")
    context = "\n".join(lines)
    for key in args_dict:
        value = str(args_dict[key])
        key = "{" + str(key) + "}"
        while key in context:
            context = context.replace(key, value)
    if not script_path is None and isinstance(script_path, str):
        save_path = os.path.dirname(script_path)
        if not os.path.exists(save_path):
            os.makedirs(save_path)
        with open(script_path, "w+", encoding="utf-8") as file:
            file.writelines(context)
        os.chmod(script_path, stat.S_IRWXU)
    else:
        context = context.replace("\r", " ").replace("\n", " ")
        while "  " in context:
            context = context.replace("  ", " ")
    return context.strip()


class packages:
    def __init__(self, args):
        self.container_name = f"{args.name}-cann{args.version}"
        self.cann_version = args.version
        self.mpich_pkg = None
        self.conda_pkg = None
        self.toolkit_pkg = None
        self.kernel_pkg = None
        self.mindspore_pkg = None
        self.torch_pkg = None

    def Check(self):
        if self.conda_pkg is None:
            print("Initialization docker container depends on Anaconda package.")
            print(f"see: {URL_ANACONDA}")
        elif self.toolkit_pkg is None:
            print("Initialization docker container depends on Ascend_toolkit package.")
            print(f"see: {URL_TOOLKIT}")
        elif self.kernel_pkg is None and self.torch_pkg is not None:
            self.torch_pkg = None
            print("torch_npu depends on ascend_kernel package, will not be installed.")
            print(f"see: {URL_TORCH_NPU}")
        elif self.mindspore_pkg is None and self.torch_pkg is None:
            print("No mindspore or torch_npu environment specified.")
            print(f"see: {URL_MINDSPORE}")
            return True
        else:
            return True
        return False

    def Get_Pkg_Name(self, Pkg_Path):
        if Pkg_Path is not None:
            Pkg_Full_Name = os.path.basename(Pkg_Path)
            [Pkg_Name, Pkg_Version] = Pkg_Full_Name.split("-")[:2]
            for Number in Pkg_Version.split("."):
                if re.match(r"^\d+$", Number):
                    Pkg_Name += f"{Number}."
            return Pkg_Name.strip(".")
        return None

    def Get_Pkg_Py(self, Pkg_Path):
        if Pkg_Path is not None:
            Pkg_Full_Name = os.path.basename(Pkg_Path)
            str_py = re.search(r"cp\d+", Pkg_Full_Name)
            if str_py is not None:
                str_py = str_py.group().replace("cp", "")
                major = int(str_py[0])
                minor = int(str_py[1:])
            return f"{major}.{minor}"
        return None

    def Copy_Resouce(self):
        pkgs_dict = {
            "mpich_pkg": self.mpich_pkg,
            "conda_pkg": self.conda_pkg,
            "toolkit_pkg": self.toolkit_pkg,
            "kernel_pkg": self.kernel_pkg,
            "cann_version": self.cann_version.upper(),
            "container_inside_path": CONTAINER_INSIDE_PATH,
            "mindspore_pkg": self.mindspore_pkg,
            "mindspore_name": self.Get_Pkg_Name(self.mindspore_pkg),
            "mindspore_py": self.Get_Pkg_Py(self.mindspore_pkg),
            "torch_pkg": self.torch_pkg,
            "torch_name": self.Get_Pkg_Name(self.torch_pkg),
            "torch_py": self.Get_Pkg_Py(self.torch_pkg),
        }
        Container_Outside_Path = f"{CONTAINER_OUTSIDE_PATH}/{self.container_name}/"
        if not os.path.exists(Container_Outside_Path):
            os.makedirs(Container_Outside_Path)
        for name, value in vars(self).items():
            if value is None or not os.path.exists(value):
                continue
            dst_path = f"{Container_Outside_Path}/{os.path.basename(value)}"
            if not os.path.exists(dst_path):
                shutil.copyfile(value, dst_path)
            pkgs_dict[name] = f"{CONTAINER_INSIDE_PATH}/{os.path.basename(value)}"
        src_script = f"{RESOURCE_PATH}/script"
        dst_script = f"{Container_Outside_Path}/script"
        if os.path.exists(dst_script):
            shutil.rmtree(dst_script)
        shutil.copytree(src_script, dst_script)
        template_path = f"{RESOURCE_PATH}/template.install.sh"
        script_path = f"{Container_Outside_Path}/.install.sh"
        __generate_script__(template_path, pkgs_dict, script_path)


def main(args):
    pkgs = __init_pkgs__(args)
    pkgs.Copy_Resouce()
    cmd_args = {
        "name": pkgs.container_name,
        "container_outside_path": CONTAINER_OUTSIDE_PATH,
        "container_inside_path": CONTAINER_INSIDE_PATH,
        "network": f"-p {args.port}:22",
    }
    if args.network == "host":
        cmd_args["network"] = "--network=host"
        print("When using the host network, the port settings will not take effect.")
    cmd_template = f"{RESOURCE_PATH}/template.create.sh"
    os.system(__generate_script__(cmd_template, cmd_args))


if __name__ == "__main__":
    try:
        main(__init_args__())
    except:
        print("\r\nProcess Terminated")
