package LANraragi::Plugin::Login::Pixiv;

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
        name      => "Pixiv 登录",  # 插件名称
        type      => "login",       # 插件类型：登录
        namespace => "pixivlogin",   # 命名空间
        author    => "psilabs-dev",  # 作者
        version   => "0.1",         # 版本号
        description =>
          "处理 Pixiv 的登录。请参阅 https://github.com/Nandaka/PixivUtil2/wiki 以获取如何获取 cookie 的信息。",  # 插件描述
        parameters => [
            { type => "string", desc => "浏览器 UserAgent（默认是 'Mozilla/5.0'）" },  # 参数：浏览器 UserAgent
            { type => "string", desc => "Cookie（PHP 会话 ID）" }  # 参数：Cookie（PHP 会话 ID）
        ]
    );

}

# 登录插件必须实现的函数
# 仅返回一个 Mojo::UserAgent 对象！
sub do_login {

    # 登录插件仅接收用户输入的参数。
    shift;
    my ( $useragent, $php_session_id ) = @_;
    return get_user_agent( $useragent, $php_session_id );
}

# 返回创建的 UA 对象。
sub get_user_agent {

    my ( $useragent, $php_session_id ) = @_;

    # 分配默认的用户代理。
    if ( $useragent eq '' ) {
        $useragent = "Mozilla/5.0";
    }

    my $logger  = get_logger( "Pixiv 登录", "插件" );
    my $ua      = Mojo::UserAgent->new;

    if ( $useragent ne "" && $php_session_id ne "") {

        # 分配用户代理。
        $ua->transactor->name($useragent);

        # 添加 Cookie
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name    =>  "PHPSESSID",
                value   =>  $php_session_id,
                domain  =>  'pixiv.net',
                path    =>  '/'
            )
        );

    } else {
        $logger->info("未提供 Cookies，返回空的 UserAgent。");
    }

    return $ua;

}

1;
