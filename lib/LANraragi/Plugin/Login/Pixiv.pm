package LANraragi::Plugin::Login::Pixiv;

use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name      => "Pixiv 登录",
        type      => "login",
        namespace => "pixivlogin",
        author    => "psilabs-dev",
        version   => "0.1",
        description =>
          "处理 Pixiv 的登录。请参阅 https://github.com/Nandaka/PixivUtil2/wiki 以获取如何获取 cookie 的信息。",
        parameters => [
            { type => "string", desc => "浏览器 UserAgent（默认值为 'Mozilla/5.0'）" },
            { type => "string", desc => "Cookie（PHP 会话 ID）" }
        ]
    );

}

# 必须实现的函数，返回一个 Mojo::UserAgent 对象
sub do_login {

    # 登录插件只接收用户输入的参数。
    shift;
    my ( $useragent, $php_session_id ) = @_;
    return get_user_agent( $useragent, $php_session_id );
}

# 返回创建的 UserAgent 对象
sub get_user_agent {

    my ( $useragent, $php_session_id ) = @_;

    # 设置默认的 UserAgent。
    if ( $useragent eq '' ) {
        $useragent = "Mozilla/5.0";
    }

    my $logger  = get_logger( "Pixiv 登录", "plugins" );
    my $ua      = Mojo::UserAgent->new;

    if ( $useragent ne "" && $php_session_id ne "") {

        # 设置 UserAgent。
        $ua->transactor->name($useragent);

        # 添加 Cookie
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name    => "PHPSESSID",
                value   => $php_session_id,
                domain  => 'pixiv.net',
                path    => '/'
            )
        );

    } else {
        $logger->info("未提供 Cookie，返回空的 UserAgent。");
    }

    return $ua;

}

1;
