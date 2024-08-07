package LANraragi::Plugin::Login::nHentai;

use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name      => "nHentai CF 绕过",
        type      => "login",
        namespace => "nhentaicfbypass",
        author    => "Pheromir",
        version   => "0.1",
        description =>
          "通过重用浏览器中的 Cookie 绕过 Cloudflare 的 JavaScript 挑战。CF Cookie 和用户代理必须来自同一个浏览器。",
        parameters => [
            { type => "string", desc => "浏览器 UserAgent 字符串（可以在 http://useragentstring.com/ 上找到你的浏览器的 UserAgent）" },
            { type => "string", desc => "用于域 nhentai.net 的 csrftoken cookie" },
            { type => "string", desc => "用于域 nhentai.net 的 cf_clearance cookie" }
        ]
    );

}

# 必须实现的函数，返回一个 Mojo::UserAgent 对象
sub do_login {

    # 登录插件只接收用户输入的参数。
    shift;
    my ( $useragent, $csrftoken, $cf_clearance ) = @_;
    return get_user_agent( $useragent, $csrftoken, $cf_clearance );
}

# 返回创建的 UserAgent 对象
sub get_user_agent {

    my ( $useragent, $csrftoken, $cf_clearance ) = @_;

    my $logger = get_logger( "nHentai Cloudflare 绕过", "plugins" );
    my $ua     = Mojo::UserAgent->new;

    if ( $useragent ne "" && $csrftoken ne "" && $cf_clearance ne "") {
        $logger->info("提供了 UserAgent 和 Cookies ($useragent $csrftoken $cf_clearance)!");
        $ua->transactor->name($useragent);

        # 设置需要的 Cookies
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
