[[Japanese description is here.]](https://github.com/ito-soft-design/escalator/blob/master/README_jp.md)

# Escalator

The escalator is a simple abstract ladder for PLC (Programmable Logic Controller).

We aim to design abstraction ladder which is able to run on any PLC with same ladder source or binary and prepare full stack tools.

# Getting started

It's required the Ruby environment.
To prepare the Ruby environment, please find web sites.

Install Escalator at the command prompt.

```
$ gem install escalator
```

# Create an Escalator project

At the command prompt, create a new Escalator project.

```
$ escalator create my_project
$ cd my_project
```

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

[![](http://img.youtube.com/vi/aFEtOIgKLvQ/0.jpg)](https://youtu.be/aFEtOIgKLvQ)

# Connection configuration

## PLC configuration

There is a plc project under the plc directory.
Launch the one of the plc project which you want to use.
(Currently we support the Emulator and MITSUBISHI iQ-R R08CUP only.)

Configure ethernet connection by the tool which is provided by plc maker.
Then upload settings and plc program to the plc.

[![](http://img.youtube.com/vi/fGdyIo9AmuE/0.jpg)](https://youtu.be/fGdyIo9AmuE)


## Escalator configuration

There is a configuration file at config/plc.yml.
Though currently we support the Emulator and MITSUBISHI iQ-R R08CUP only, you only change host to an ip address of your plc.

```plc.yml
plc:
  iq-r:                     # It's a target name
    cpu: iq-r               # It's just a comment.
    protocol: mc_protocol   # It's a protocl to communicate with PLC.
    host: 192.168.0.10      # It's PLC's IP address or dns name.
    port: 5007              # It's PLC's port no.
```

[![](http://img.youtube.com/vi/m0JaOBFIHqw/0.jpg)](https://youtu.be/m0JaOBFIHqw)


## Escalator programming

Escalator program file is located under the asm directory.
By default, use asm/main.esc.
Edit it and programming.

Refer [Wiki](https://github.com/ito-soft-design/escalator/wiki/mnemonic) to check mnemonic.

```
LD  M0
AND M1
OUT M2
END
```

[![](http://img.youtube.com/vi/OjaSqrkWv8Q/0.jpg)](https://youtu.be/OjaSqrkWv8Q)


# Transfer the Escalator program

At the command prompt, use ```rake``` command to upload escalator program to the plc.
By default, the target plc is ```emulator```. Then launch the Emulator.

```sh
$ rake
```

If you use with the ```target``` option, the target PLC is it.

```sh
$ rake target=iq-r
```

You can describe the default target by the target section in plc.yml.

```plc.yml
default:
  target: iq-r
```

```rake``` is same as ```rake target=iq-r```.


The Escalator program runs immediately after uploaded.

```
$ rake [target=iq-r]
uploading build/main.hex ...
launching emulator ...
done launching
done uploading

  Escalator is an abstract PLC.
  This is a console to communicate with PLC.

>
```

After uploaded the program, it becomes in to console mode.
You can read and write a device by entering commands.

Use the r command if you want to read devices.
Below example reads values of devices from M0 to M7.

```
> r m0 8
```

Below example writes values to devices from M0 to M7.

```
> w m0 0 0 0 1 1 0 1 1
```


[![](http://img.youtube.com/vi/qGbicGLB7Gs/0.jpg)](https://youtu.be/qGbicGLB7Gs)


# Information related escalator

- [My japanese diary [escalator]](http://diary.itosoft.com/?category=escalator)
- [Wiki](https://github.com/ito-soft-design/escalator/wiki/)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
