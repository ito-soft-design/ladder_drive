[[Japanese description is here.]](https://github.com/ito-soft-design/ladder_drive/blob/master/README_jp.md)

# LadderDrive

The ladder_drive is a simple abstract ladder for PLC (Programmable Logic Controller).

We aim to design abstraction ladder which is able to run on any PLC with same ladder source or binary and prepare full stack tools.

# Getting started

It's required the Ruby environment.
To prepare the Ruby environment, please find web sites.

Install LadderDrive at the command prompt.

```sh
$ gem install ladder_drive
```

[![https://gyazo.com/6f00d74612def41fb33d836275b74c24](https://i.gyazo.com/6f00d74612def41fb33d836275b74c24.gif)](https://gyazo.com/6f00d74612def41fb33d836275b74c24)

# Create an LadderDrive project

At the command prompt, create a new LadderDrive project.

```sh
$ ladder_drive create my_project
$ cd my_project
```

[![https://gyazo.com/c538f66129aa425e2b1da4f478a10f52](https://i.gyazo.com/c538f66129aa425e2b1da4f478a10f52.gif)](https://gyazo.com/c538f66129aa425e2b1da4f478a10f52)

Created files are consisted like the tree below.

```
.
├── Rakefile
├── asm
│   └── main.esc
├── config
│   └── plc.yml
└── plc
    └── mitsubishi
        └── iq-r
            └── r08
                ├── LICENSE
                └── r08.gx3
```

# Connection configuration

## PLC configuration

There is a plc project under the plc directory.
Launch the one of the plc project which you want to use.
(Currently we support the Emulator and MITSUBISHI iQ-R R08CUP only.)

Configure ethernet connection by the tool which is provided by plc maker.
Then upload settings and plc program to the plc.

[![](http://img.youtube.com/vi/fGdyIo9AmuE/0.jpg)](https://youtu.be/fGdyIo9AmuE)


## LadderDrive configuration

There is a configuration file at config/plc.yml.
Currently we support MITSUBISHI iQ-R R08CUP and the Emulator.
You only change host to an ip address of your plc.

```
# plc.yml
plc:                        # Beginning of PLC section.
  iq-r:                     # It's a target name
    cpu: iq-r               # It's just a comment.
    protocol: mc_protocol   # It's a protocol to communicate with PLC.
    host: 192.168.0.10      # It's PLC's IP address or dns name.
    port: 5007              # It's PLC's port no.
```

[![](http://img.youtube.com/vi/m0JaOBFIHqw/0.jpg)](https://youtu.be/m0JaOBFIHqw)


## LadderDrive programming

LadderDrive program file is located under the asm directory.
By default, use asm/main.esc.
Edit it and programming.

Refer [Wiki](https://github.com/ito-soft-design/ladder_drive/wiki/mnemonic) to check mnemonic.

```
# main.esc
# |M0|-|M1|----(M2)
LD  M0
AND M1
OUT M2
END
```

[![](http://img.youtube.com/vi/OjaSqrkWv8Q/0.jpg)](https://youtu.be/OjaSqrkWv8Q)


# Transfer the LadderDrive program

At the command prompt, use ```rake``` command to upload ladder_drive program to the plc.
By default, the target plc is ```emulator```. Then launch the Emulator.

```sh
$ rake
```

If you use with the ```target``` option, the target PLC is it.

```sh
$ rake target=iq-r
```

You can describe the default target by the target section in plc.yml.

```
# plc.yml
default:
  target: iq-r
```

```rake``` is same as ```rake target=iq-r```.


The LadderDrive program runs immediately after uploaded.

```sh
$ rake [target=iq-r]
uploading build/main.hex ...
launching emulator ...
done launching
done uploading

  LadderDrive is an abstract PLC.
  This is a console to communicate with PLC.

>
```

After uploaded the program, it becomes in to console mode.
You can read and write a device by entering commands.

Use the r command if you want to read devices.
Below example reads values of devices from M0 to M7.

```sh
> r m0 8
```

Below example writes values to devices from M0 to M7.

```sh
> w m0 0 0 0 1 1 0 1 1
```

If you want to turn on and off the device like pushing a button, use p command.

```sh
> p m0
```

You can describe turn on time duration after a device. The unit is sec.

```sh
> p m0 1.5
```

```
# |M0|---(M1)
LD  M0
OUT M1
```

[![https://gyazo.com/565d24a35887503281a46775f6ccd747](https://i.gyazo.com/565d24a35887503281a46775f6ccd747.gif)](https://gyazo.com/565d24a35887503281a46775f6ccd747)

<!-- [![](http://img.youtube.com/vi/qGbicGLB7Gs/0.jpg)](https://youtu.be/qGbicGLB7Gs) -->


## Raspberry Pi

You can run it on the Raspberry Pi.
X or Y devices are assigned to GPIOs.

### Installation

```sh
$ sudo apt-get update
$ sudo apt-get install ruby-dev
$ sudo apt-get install libssl-dev
$ sudo gem install ladder_drive --no-ri --no-rdoc
```

### Execution

```sh
$ ladder_drive create project
$ cd project
$ sudo rake target=raspberrypi
```

### I/O settings

You can describe io configuration by confing/plc.yml file.
Define inputs pins by inputs section.
Devine outputs pins by outptus section.
You can specify pull up or pull down and invert options for input.

```
  # Raspberry Pi
  raspberrypi:
    cpu: Raspberry Pi
    io: # assign gpio to x and y
      inputs:
        x0:
          pin: 4        # gpio no
          pull: up      # up | down | off
          invert: true
        x1:
          pin: 17
          pull: up
          invert: true
        x2:
          pin: 27
          pull: up
          invert: true
      outputs:
        y0:
          pin: 18
        y1:
          pin: 23
        y2:
          pin: 42
```

### Run Ladder Drive as a service

Follow these steps to run ladder drive as a service at your project directory.

```
$ sudo rake service:install
$ sudo rake service:enable
$ sudo rake service:start
```
[![LadderDrive on Raspberry Pi](http://img.youtube.com/vi/UBhSaRNp_gM/0.jpg)](http://www.youtube.com/watch?v=UBhSaRNp_gM)


# Accessing a device values

You can use LadderDrive as a accessing tool for the PLC device.

You can read/write device like this.

```
require 'ladder_drive'

plc = LadderDrive::Protocol::Mitsubishi::McProtocol.new host:"192.168.0.10"

plc["M0"] = true
plc["M0"]         # => true
plc["M0", 10]     # => [true, false, ..., false]

plc["D0"] = 123
plc["D0"]       # => 123
plc["D0", 10] = [0, 1, 2, ..., 9]
plc["D0".."D9"]   => [0, 1, 2, ..., 9]
```

# Information related ladder_drive

- [My japanese diary [ladder_drive]](http://diary.itosoft.com/?category=ladder_drive)
- [Wiki](https://github.com/ito-soft-design/ladder_drive/wiki/)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
