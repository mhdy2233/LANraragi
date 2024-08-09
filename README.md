*该版本为官方版0.9.21*
LANraragi   
===========

开源漫画/漫画存档服务器，基于Mojolicious + Redis运行。

默认使用存储卷可根据需要自行更换为本机目录，存储卷须手动提升权限777

**docker安装请docker pull mhdy2233/lanraragi_cn_mhdy:0.2**

**1panel安装请将该目录https://github.com/mhdy2233/appstore/tree/localApps/apps/lanraragi 下载到该路径1panel/resource/apps/local/**

#### 💬 与其他LANraragi用户在[Discord](https://discord.gg/aRQxtbg)或[GitHub Discussions](https://github.com/Difegue/LANraragi/discussions)交流  

####  [📄 文档](https://sugoi.gitbook.io/lanraragi/v/dev) | [⏬ 下载](https://github.com/Difegue/LANraragi/releases/latest) | [🎞 演示](https://lrr.tvc-16.science) | [🪟🌃 Windows Nightlies](https://nightly.link/Difegue/LANraragi/workflows/push-continous-delivery/dev) | [💵 赞助开发](https://ko-fi.com/T6T2UP5N)  

## 截图

|主页，缩略图视图 | 主页，列表视图 |
|---|---|
| [![archive_thumb](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/archive_thumb.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/archive_thumb.png) | [![archive_list](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/archive_list.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/archive_list.png) |

|档案阅读器 | 带叠加层的阅读器 |
|---|---|
| [![reader](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/reader.jpg)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/reader.jpg) | [![reader_overlay](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/reader_overlay.jpg)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/reader_overlay.jpg) |

|配置 | 插件配置 |
|---|---|
| [![cfg](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/cfg_plugin.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/cfg.png) | [![cfg_plugin](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/cfg_plugin.png)](https://raw.githubusercontent.com/Difegue/LANraragi/dev/tools/_screenshots/cfg_plugin.png) |

## 特点

* 将漫画存储为压缩档案格式。（支持zip/rar/targz/lzma/7z/xz/cbz/cbr/pdf，基本支持epub）

* 直接从Web浏览器读取档案：服务器使用临时文件夹从压缩文件中读取。

* 使用内置的OPDS目录（现已支持PSE）在专用阅读器软件中阅读你的档案！

* 使用客户端API与LANraragi进行交互（适用于[多种平台！](https://sugoi.gitbook.io/lanraragi/v/dev/advanced-usage/external-readers)）

* 两种不同的用户界面：带悬停缩略图的紧凑档案列表或缩略图视图。

* 从5种预装的响应式库样式中选择，或使用CSS添加自己的样式。

* 完整的标签支持和命名空间：添加自己的标签或使用插件从其他来源导入。

* 将档案存储在任意或动态分类中，轻松排序你的库。

* 在档案添加到LANraragi时，使用插件自动导入元数据。

* 直接从互联网下载档案到服务器，同时使用上述的自动元数据导入。

* 将数据库备份为JSON格式，将标签转移到另一个LANraragi实例。

## 提交PR，获取贴纸™

合并到此repo的PR（或捐赠$5以上）有资格获得[免费贴纸包](https://forms.office.com/Pages/ResponsePage.aspx?id=DQSIkWdsW0yxEjajBLZtrQAAAAAAAAAAAAN__osxt25URTdTUTVBVFRCTjlYWFJLMlEzRTJPUEhEVy4u)。
