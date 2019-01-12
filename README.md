# SayHi

## 前言

Logos 是 [Theos](https://github.com/theos/theos) 的一个组件，它允许程序员使用一组特殊的预处理器指令来编写钩子，简洁高效。
做过 iOS 逆向开发的朋友应该非常熟悉，这里笔者将介绍如何在 Mac app 上使用 Logos。

## 可能用到的工具

1.  [Theos](https://github.com/theos/theos)
2.  [optool](https://github.com/alexzielenski/optool)/[insert_dylib](https://github.com/Tyilo/insert_dylib)
3.  [unsign](https://github.com/steakknife/unsign) (optional)

---

## 一个简单的例子

-   编写一个简单的 demo，大概就是  软件正中一个按钮，点击之后 alert("hi!")。核心代码如下：

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

    ![效果图](https://i.imgur.com/ao2FHon.png)

我们的目标是注入 sayHi 这个方法，使点击按钮之后不再说“hi!”，而是“hello world!”

-   编写 Logos

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

将以上代码保存为一个 Tweak.xm 文件(名字后缀名随意)，放在与 SayHi.app 同级目录下，便于后续操作。

-   然后我们使用 Theos 的语法分析来把 Logos 转换成普通代码
    `$THEOS/bin/logos.pl Tweak.xm > abc.mm`
    _注意 abc 应该有 mm 作为后缀名，用于告诉 clang 目标语言类型_

-   使用 clang 编译转换后的普通代码，并将结果放到 app 包内
    `clang -shared -undefined dynamic_lookup -o ./SayHi.app/Contents/MacOS/lib.dylib ./abc.mm`

-   使用 optool/insert_dylib 往 SayHi 的 MachO 头部添加我们刚刚编译的 lib.dylib
    `optool install -c load -p @executable_path/lib.dylib -t ./SayHi.app/Contents/MacOS/SayHi`

如果你的 Mac app 没有签名的话，此时应该已经达成我们的需求了。但是实践中我们肯定不是对自己导出的未签名 Mac app 下黑手。所以需要去掉这个签名或重签名。因为笔者没有钱买开发者账号，故不知道如何重签名。

-   使用 codesign 去除签名
    `codesign --remove-signature SayHi.app`

此时我们的需求已经达成

![大成功](https://i.imgur.com/pcCawwB.png)

但是 codesign 有一个 bug，在删除代码签名之后没有修复 MachO Header 的偏移，会导致生成的 MachO 文件畸形。笔者曾经就遇见一个不到 1m 的小程序在移除签名后膨胀到 2g 大小。
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

[下载 Demo](https://github.com/0x11901/SayHi)
