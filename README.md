# Img4ye 图片采集插件
### 使用说明
#### 服务端
https://github.com/mindpin/image-service/tree/0.3-dev

#### 插件导入说明
```
你需要安装有node(只测试过0.12.4)以及ruby(~> 2.2.0)
```

你需要修改配置文件**lib/scripts/base.coffee**，然后运行一下指令：
```shell
npm install
bundle install
gulp watch
```

插件则会生成在**dist/**目录下，使用chrome导入即可开始使用。
