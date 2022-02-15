import yaml
import subprocess

if __name__ == "__main__":
    corners_str = open("./corners.yml").read()
    corners_by_scl = yaml.safe_load(corners_str)
    for scl, corners in corners_by_scl.items():
        subprocess.run(
            [
                "python3",
                "-m",
                "skywater_pdk.liberty",
                f"libraries/{scl}/latest",
                *corners,
            ]
        )
