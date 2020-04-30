# p4-xor-test

Quoted from my post in P4's Slack group:

I have noticed that in p4c 1.2.0 (SHA: b1374a14), specifically nested conditional actions, arithmetic/ other operations (e.g. XOR) would be "ignored". While in the tutorials VM with p4c 1.1.0-rc1 (SHA: fa2d9014), it works fine. </br>

Here is an example used to reproduce the issue on both p4c versions, https://github.com/khooi8913/p4-op-in-condition/blob/e64e22b0d5b9b2f69cebe4700db869decc09cfb8/src/p4-xor-test.p4#L119. </br>

Look out for Line 122-135. There are 2 nested conditional actions, followed by 2 straight-line code performing similar operations. I have a debug table that prints out the changes of the values (denoted by beforeX, afterX) in the actions. </br>

p4c 1.1.0-rc1 (SHA: fa2d9014)
```
[06:56:04.855] [bmv2] [T] [thread 2203] [29.0] [cxt 0] Applying table 'MyIngress.debug'
[06:56:04.855] [bmv2] [D] [thread 2203] [29.0] [cxt 0] Looking up key:
* meta.before1        : 0a000101
* meta.after1         : 18345779
* meta.before2        : 0a000102
* meta.after2         : 1834577a
* meta.before3        : 18345779
* meta.after3         : 0a000101
* meta.before4        : 1834577a
* meta.after4         : 0a000102
```
p4c 1.2.0 (SHA: b1374a14)
```
[10:20:05.788] [bmv2] [T] [thread 10593] [34.0] [cxt 0] Applying table 'MyIngress.debug'
[10:20:05.788] [bmv2] [D] [thread 10593] [34.0] [cxt 0] Looking up key:
* meta.before1        : 18345779
* meta.after1         : 18345779
* meta.before2        : 1834577a
* meta.after2         : 1834577a
* meta.before3        : 18345779
* meta.after3         : 0a000101
* meta.before4        : 1834577a
* meta.after4         : 0a000102
```
Notice that in p4c 1.2.0, for (1) and (2) which corresponds to the nested conditional actions, the XOR/ arithmetic operations was somehow "ignored", while in p4c 1.1.0 it works fine.
