# Escalator

The escalator is a simple abstract ladder for PLC (Programmable Logic Controller).

We aim to design runnable abstraction ladder which is running on any PLC with same ladder source or binary and prepare full stack tools.

# Getting started

It's required the Ruby environment.
To prepare Ruby environment, please find web sites.

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

Created files are consisted like below the tree.

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

<iframe width="560" height="315" src="https://www.youtube.com/embed/aFEtOIgKLvQ" frameborder="0" allowfullscreen></iframe>

# Connection configuration

## PLC configuration

There is a plc project under the plc directory.
Launch the one of the plc project which you want to use.
(Currently we support MITSUBISHI iQ-R R08CUP only.)

Configure ethernet connection by the tool which is provided by plc maker.
Then upload settings and plc program to the plc.

<iframe width="560" height="315" src="https://www.youtube.com/embed/fGdyIo9AmuE" frameborder="0" allowfullscreen></iframe>


## Escalator configuration

There is a configuration file at config/plc.yml.
Though currently we support MITSUBISHI iQ-R R08CUP only, you only change host to an ip address of your plc.

```
:plc:
  :cpu: iq-r
  :protocol: mc_protocol
  :host: 192.168.0.1
  :port: 5007
  :program_area: d10000
  :interaction_area: d9998
```

<iframe width="560" height="315" src="https://www.youtube.com/embed/m0JaOBFIHqw" frameborder="0" allowfullscreen></iframe>


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

<iframe width="560" height="315" src="https://www.youtube.com/embed/OjaSqrkWv8Q" frameborder="0" allowfullscreen></iframe>


# Transfer the Escalator program

At the command prompt, use rake command to upload escalator program to the plc.
The Escalator program is running immediate after uploaded.

```
$ rake plc
```

<iframe width="560" height="315" src="https://www.youtube.com/embed/qGbicGLB7Gs" frameborder="0" allowfullscreen></iframe>


# Information related escalator

- [My japanese diary [escalator]](http://diary.itosoft.com/?category=escalator)
- [Wiki](https://github.com/ito-soft-design/escalator/wiki/)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
