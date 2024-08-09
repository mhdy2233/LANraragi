package LANraragi::Plugin::Login::Fakku;

use utf8;
use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

sub plugin_info {

    return (
        name      => "Fakku",  # 插件名称
        type      => "login",  # 插件类型：登录
        namespace => "fakkulogin",  # 命名空间
        author    => "Nodja",  # 作者
        version   => "0.1",    # 版本号
        description =>
          "处理 Fakku 的登录。Cookie 仅在 7 天内有效，因此不要忘记更新它。",  # 插件描述
        parameters => [
            { type => "string", desc => "fakku_sid cookie 值" }  # 参数：fakku_sid cookie 值
        ]
    );

}

sub do_login {

    shift;
    my ( $fakku_sid ) = @_;

    my $logger = get_logger( "Fakku 登录", "插件" );
    my $ua     = Mojo::UserAgent->new;

    if ( $fakku_sid ne "" ) {
        $logger->info("提供的 Cookie ($fakku_sid)!");
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'fakku_sid',
                value  => $fakku_sid,
                domain => 'fakku.net',
                path   => '/'
            )
        );
    } else {
        $logger->info("未提供 Cookies，返回空的 UserAgent。");
    }

    return $ua;
}
1;
