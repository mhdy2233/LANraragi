package LANraragi::Plugin::Scripts::nHentaiSourceConverter;

use utf8;    # 添加这一行以支持 UTF-8 编码
use strict;
use warnings;
no warnings 'uninitialized';

use LANraragi::Utils::Logging qw(get_plugin_logger);
use LANraragi::Utils::Database qw(invalidate_cache set_tags);
use LANraragi::Model::Config;

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name        => "nHentai 来源转换器",
        type        => "script",
        namespace   => "nhsrcconv",
        author      => "Guerra24",
        version     => "1.0",
        description => "将 \"source:{id}\" 标签中的 6 位或更少的数字转换为 \"source:nhentai.net/g/{id}\""
    );

}

# 必须由脚本实现的函数
sub run_script {
    shift;
    my $lrr_info = shift;    # 全局信息哈希

    my $logger = get_plugin_logger();
    my $redis  = LANraragi::Model::Config->get_redis;

    my @keys = $redis->keys('????????????????????????????????????????');    # 只处理 40 字符长的键 => 归档 ID

    my $count = 0;

    # 解析归档列表并将其添加到 JSON 中。
    foreach my $id (@keys) {

        my %hash = $redis->hgetall($id);
        my ($tags) = @hash{qw(tags)};

        if ( $tags =~ s/source:(\d{1,6})/source:nhentai\.net\/g\/$1/igm ) {
            $count++;
        }

        set_tags( $id, $tags );
    }

    invalidate_cache();
    $redis->quit();

    return ( modified => $count );
}

1;
