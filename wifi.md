## Docs
- [arch wiki link](https://wiki.archlinux.org/title/Network_configuration/Wireless#Check_the_driver_status)
- From [This arch wiki post](https://bbs.archlinux.org/viewtopic.php?id=248549)

> What is the output of the following command?
> 
```
lsmod | grep rtl
```
>
> If you do not see rtl8821ae in the list, try to manually load it with
```
modprobe rtl8821ae
```
> If that fails, post the error message.

## Driver
[rtl8188ee](https://github.com/FreedomBen/rtl8188ce-linux-driver)
