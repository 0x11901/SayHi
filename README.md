# SayHi


## 前言
Logos是[Theos](https://github.com/theos/theos)的一个组件，它允许程序员使用一组特殊的预处理器指令来编写钩子，简洁高效。
做过iOS逆向开发的朋友应该非常熟悉，这里笔者将介绍如何在Mac app上使用Logos。

## 可能用到的工具
1. [Theos](https://github.com/theos/theos)
2. [optool](https://github.com/alexzielenski/optool)/[insert_dylib](https://github.com/Tyilo/insert_dylib)
2. [unsign](https://github.com/steakknife/unsign) (optional)

## 一个简单的例子
* 编写一个简单的demo，大概就是软件正中一个按钮，点击之后alert("hi!")。核心代码如下：

    ```objc
    #import "ViewController.h"
    
    @implementation ViewController
    
    - (void)viewDidLoad {
        [super viewDidLoad];
    
        // Do any additional setup after loading the view.
    }
    
    - (IBAction)sayHi:(NSButton *)sender {
        NSAlert *alert = NSAlert.new;
        alert.messageText = @"hi!";
        alert.alertStyle = NSAlertStyleInformational;
        [alert runModal];
    }
    
    
    - (void)setRepresentedObject:(id)representedObject {
        [super setRepresentedObject:representedObject];
    
        // Update the view, if already loaded.
    }
    
    
    @end
    ```
![效果图](http://ooph3gs8p.bkt.clouddn.com/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-02-10%2021.53.36.png)

我们的目标是注入sayHi这个方法，使点击按钮之后不再说“hi!”，而是“hello world!”
* 编写Logos

    ```objc
    %config(generator=internal)
    
    // You don't need to #include <substrate.h>, it will be done automatically, as will
    // the generation of a class list and an automatic constructor.
    #import <Foundation/Foundation.h>
    
    %hook ViewController
    
    
    // Hooking an instance method with an argument.
    - (void)sayHi:(id)argument {
        NSAlert *r15 = [[NSAlert alloc] init];
        [r15 setMessageText:@"hello world!"];
        [r15 setAlertStyle:0x1];
        [r15 runModal];
    }
    
    
    
    // Always make sure you clean up after yourself; Not doing so could have grave consequences!
    %end
    
    %ctor {
        NSLog(@"!!!!!!inject success!!!!!!!");
    }
    ```
将以上代码保存为一个Tweak.xm文件(名字后缀名随意)，放在与SayHi.app同级目录下，便于后续操作。

* 然后我们使用Theos的语法分析来把Logos转换成普通代码
`$THEOS/bin/logos.pl Tweak.xm > abc.mm`
*注意abc应该有mm作为后缀名，用于告诉clang目标语言类型*

* 使用clang编译转换后的普通代码，并将结果放到app包内
    `clang -shared -undefined dynamic_lookup -o ./SayHi.app/Contents/MacOS/lib.dylib ./abc.mm`
    
* 使用optool/insert_dylib往SayHi的MachO头部添加我们刚刚编译的lib.dylib
    `optool install -c load -p @executable_path/lib.dylib -t ./SayHi.app/Contents/MacOS/SayHi`

如果你的Mac app没有签名的话，此时应该已经达成我们的需求了。但是实践中我们肯定不是对自己导出的未签名Mac app下黑手。所以需要去掉这个签名或重签名。因为笔者没有钱买开发者账号，故不知道如何重签名。

* 使用codesign去除签名
`codesign --remove-signature SayHi.app `

此时我们的需求已经达成
![大成功](http://ooph3gs8p.bkt.clouddn.com/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-02-10%2023.14.23.png)
但是codesign有一个bug，在删除代码签名之后没有修复MachO Header的偏移，会导致生成的MachO文件畸形。笔者曾经就遇见一个不到1m的小程序在移除签名后膨胀到2g大小。
所以笔者建议使用开源社区的代替方案——[unsign](https://github.com/steakknife/unsign) 

## 后记
笔者把上面的繁琐命令行操作整合为一个脚本，在这里也顺便分享出来

```bash
#!/usr/bin/env bash

#将xm和文件app包放在同一个目录，运行本脚步进行注入

path=`ls | grep *.app | head -1`
tweak=`ls | grep *.xm | head -1`
temp='x11901'
name=${path%.app}

$THEOS/bin/logos.pl "./${tweak}" > "./${temp}.m"
clang -shared -undefined dynamic_lookup -o "./${path}/Contents/MacOS/lib.dylib" "./${temp}.mm"
optool install -c load -p @executable_path/lib.dylib -t "./${path}/Contents/MacOS/${name}"

rm -f ${temp}.m

# 使用unsign效果可能更好，codesign --remove-signature 在删除代码签名之后没有修复MachO Header的偏移，导致生成的MachO文件畸形
# codesign --remove-signature ${name}
if [ ! -e "./${path}/Contents/MacOS/${name}.ori" ]; then
    unsign "./${path}/Contents/MacOS/${name}"
    mv "./${path}/Contents/MacOS/${name}" "./${path}/Contents/MacOS/${name}.ori"
    mv "./${path}/Contents/MacOS/${name}.unsigned" "./${path}/Contents/MacOS/${name}"
fi

open "./${path}/Contents/MacOS/${name}"
```
---
[下载Demo](https://github.com/0x11901/SayHi)

