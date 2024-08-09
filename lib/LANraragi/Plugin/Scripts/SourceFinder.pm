package LANraragi::Plugin::Scripts::SourceFinder;

use utf8;    # 添加这一行以支持 UTF-8 编码
use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_plugin_logger);
use LANraragi::Model::Stats;
use LANraragi::Utils::String qw(trim_url);

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name        => "来源查找器",
        type        => "script",
        namespace   => "urlfinder",
        author      => "Difegue",
        version     => "2.0",
        description => "检查数据库中是否有与给定 URL 匹配的 'source:' 标签的归档。",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAIAAAAC64paAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABZSURBVDhPzY5JCgAhDATzSl+e/2irOUjQSFzQog5hhqIl3uBEHPxIXK7oFXwVE+Hj5IYX4lYVtN6MUW4tGw5jNdjdt5bLkwX1q2rFU0/EIJ9OUEm8xquYOQFEhr9vvu2U8gAAAABJRU5ErkJggg==",
        oneshot_arg => "要搜索的 URL。"
    );

}

# 必须由脚本实现的函数
sub run_script {
    shift;
    my $lrr_info = shift;                 # 全局信息哈希
    my $logger   = get_plugin_logger();

    # 我们需要的信息只有要搜索的 URL
    my $url = $lrr_info->{oneshot_param};
    $logger->debug( "正在查找 URL " . $url );

    trim_url($url);

    if ( $url eq "" ) {
        return ( error => "未指定 URL！", total => 0 );
    }

    my $recorded_id = LANraragi::Model::Stats::is_url_recorded($url);
    if ($recorded_id) {
        return (
            total => 1,
            id    => $recorded_id
        );
    }

    # 针对 EH/Ex URL 的特定变体，我们还会检查其他域名。
    my $last_chance_id = "";
    if ( $url =~ /https?:\/\/exhentai\.org\/g\/([0-9]*)\/([0-z]*)\/*.*/gi ) {
        my $url2 = "https://e-hentai.org/g/$1/$2";
        $last_chance_id = LANraragi::Model::Stats::is_url_recorded($url2);
    }

    if ( $url =~ /https?:\/\/e-hentai\.org\/g\/([0-9]*)\/([0-z]*)\/*.*/gi ) {
        my $url2 = "https://exhentai.org/g/$1/$2";
        $last_chance_id = LANraragi::Model::Stats::is_url_recorded($url);
    }

    if ($last_chance_id) {
        return (
            total => 1,
            id    => $last_chance_id
        );
    }

    return ( error => "数据库中未找到 URL。", total => 0 );
}

1;
