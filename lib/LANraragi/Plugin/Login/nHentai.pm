package LANraragi::Plugin::Login::nHentai;

use utf8;
use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

# 关于插件的元信息。
sub plugin_info {

    return (
        # 标准元数据
        name      => "nHentai CF 绕过",  # 插件名称
        type      => "login",           # 插件类型：登录
        namespace => "nhentaicfbypass",  # 命名空间
        author    => "Pheromir",         # 作者
        version   => "0.1",             # 版本号
        description =>
          "通过重用浏览器中的 cookies 绕过 Cloudflare Javascript 挑战。CF cookies 和用户代理必须来自同一网页浏览器。",  # 插件描述
        parameters => [
            { type => "string", desc => "浏览器 UserAgent 字符串（可以在 http://useragentstring.com/ 查找你的浏览器）" },  # 参数：浏览器 UserAgent 字符串
            { type => "string", desc => "nhentai.net 域的 csrftoken cookie" },  # 参数：csrftoken cookie
            { type => "string", desc => "nhentai.net 域的 cf_clearance cookie" }  # 参数：cf_clearance cookie
        ]
    );

}

# 登录插件必须实现的函数
# 仅返回一个 Mojo::UserAgent 对象！
sub do_login {

    # 登录插件仅接收用户输入的参数。
    shift;
    my ( $useragent, $csrftoken, $cf_clearance ) = @_;
    return get_user_agent( $useragent, $csrftoken, $cf_clearance );
}

# 返回创建的 UA 对象。
sub get_user_agent {

    my ( $useragent, $csrftoken, $cf_clearance ) = @_;

    my $logger = get_logger( "nHentai Cloudflare 绕过", "插件" );
    my $ua     = Mojo::UserAgent->new;

    if ( $useragent ne "" && $csrftoken ne "" && $cf_clearance ne "") {
        $logger->info("提供的 Useragent 和 Cookies ($useragent $csrftoken $cf_clearance)!");
        $ua->transactor->name($useragent);

        # 设置所需的 cookies
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'csrftoken',
                value  => $csrftoken,
                domain => 'nhentai.net',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'cf_clearance',
                value  => $cf_clearance,
                domain => 'nhentai.net',
                path   => '/'
            )
        );

    } else {
        $logger->info("未提供 Cookies，返回空的 UserAgent。");
    }

    return $ua;

}

1;
