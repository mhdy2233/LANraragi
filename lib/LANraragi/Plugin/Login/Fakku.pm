package LANraragi::Plugin::Login::Fakku;

use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

sub plugin_info {

    return (
        name      => "Fakku",
        type      => "login",
        namespace => "fakkulogin",
        author    => "Nodja",
        version   => "0.1",
        description =>
          "处理 Fakku 登录。Cookie 仅在 7 天内有效，请不要忘记更新它。",
        parameters => [
            { type => "string", desc => "fakku_sid cookie 值" }
        ]
    );

}

sub do_login {

    shift;
    my ( $fakku_sid ) = @_;

    my $logger = get_logger( "Fakku 登录", "plugins" );
    my $ua     = Mojo::UserAgent->new;

    if ( $fakku_sid ne "" ) {
        $logger->info("提供了 Cookie ($fakku_sid)!");
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'fakku_sid',
                value  => $fakku_sid,
                domain => 'fakku.net',
                path   => '/'
            )
        );
    } else {
        $logger->info("没有提供 Cookies，返回空的 UserAgent。");
    }

    return $ua;
}
1;
