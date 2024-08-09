package LANraragi::Plugin::Download::Chaika;
use utf8;
use strict;
use warnings;
no warnings 'uninitialized';

# 关于插件的元信息。
sub plugin_info {

    return (
        # 标准元数据
        name        => "Chaika.moe 下载器",             # 插件名称
        type        => "download",                    # 插件类型：下载器
        namespace   => "chaikadl",                    # 命名空间
        author      => "Difegue",                     # 作者
        version     => "1.0",                         # 版本号
        description => "下载给定的 chaika.moe 链接并将其添加到 LANraragi。暂不支持画廊链接！",  # 插件描述

        # 下载器特定的元数据
        # https://panda.chaika.moe/archive/_____/
        url_regex => "https?:\/\/panda.chaika.moe\/archive\/.*"  # URL 正则表达式
    );

}

# 下载器必须实现的函数
sub provide_url {
    shift;
    my $lrr_info = shift;

    # 获取要下载的 URL
    my $url = $lrr_info->{url};

    # 哇！
    return ( download_url => $url . "/download" );  # 返回带有 /download 后缀的下载链接
}

1;
