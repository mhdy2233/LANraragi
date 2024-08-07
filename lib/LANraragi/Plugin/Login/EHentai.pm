package LANraragi::Plugin::Login::EHentai;

use strict;
use warnings;
no warnings 'uninitialized';

use Mojo::UserAgent;
use LANraragi::Utils::Logging qw(get_logger);

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name      => "E-Hentai",
        type      => "login",
        namespace => "ehlogin",
        author    => "Difegue",
        version   => "2.3",
        description =>
          "处理E-Hentai登录。如果你有一个可以访问 fjorded 内容或 exhentai 的帐户，添加这些凭据将使更多档案可用于解析。",
        parameters => [
            { type => "int",    desc => "ipb_member_id cookie" },
            { type => "string", desc => "ipb_pass_hash cookie" },
            { type => "string", desc => "star cookie（可选，如果存在则可以在没有 exhentai 的情况下查看 fjorded 内容）" },
            { type => "string", desc => "igneous cookie（可选，如果存在则可以在没有欧洲和美国 IP 的情况下查看 exhentai）" }
        ]
    );

}

# 必须由登录插件实现的函数
# 返回一个 Mojo::UserAgent 对象！
sub do_login {

    # 登录插件仅接收用户输入的参数。
    shift;
    my ( $ipb_member_id, $ipb_pass_hash, $star ,$igneous ) = @_;
    return get_user_agent( $ipb_member_id, $ipb_pass_hash, $star ,$igneous );
}

# get_user_agent(ipb cookies)
# 尝试创建一个 Mojo::UserAgent 对象，以便访问 E-Hentai。
# 返回创建的 UA 对象。
sub get_user_agent {

    my ( $ipb_member_id, $ipb_pass_hash, $star, $igneous ) = @_;

    my $logger = get_logger( "E-Hentai 登录", "plugins" );
    my $ua     = Mojo::UserAgent->new;

    if ( $ipb_member_id ne "" && $ipb_pass_hash ne "" ) {
        $logger->info("提供了 Cookies ($ipb_member_id $ipb_pass_hash $star $igneous)!");

        # 设置所需的 cookies 用于两个域名
        # 它们应该会转化为带有 igneous 值的 exhentai cookies
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'ipb_member_id',
                value  => $ipb_member_id,
                domain => 'exhentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'ipb_member_id',
                value  => $ipb_member_id,
                domain => 'e-hentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'ipb_pass_hash',
                value  => $ipb_pass_hash,
                domain => 'exhentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'ipb_pass_hash',
                value  => $ipb_pass_hash,
                domain => 'e-hentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'star',
                value  => $star,
                domain => 'exhentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'igneous',
                value  => $igneous,
                domain => 'exhentai.org',
                path   => '/'
            )
        );
        
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'star',
                value  => $star,
                domain => 'e-hentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'igneous',
                value  => $igneous,
                domain => 'e-hentai.org',
                path   => '/'
            )
        );
        
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'ipb_coppa',
                value  => '0',
                domain => 'forums.e-hentai.org',
                path   => '/'
            )
        );

        # 跳过“攻击性警告”屏幕，以便可以轻松获取画廊档案 gID。
        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'nw',
                value  => '1',
                domain => 'exhentai.org',
                path   => '/'
            )
        );

        $ua->cookie_jar->add(
            Mojo::Cookie::Response->new(
                name   => 'nw',
                value  => '1',
                domain => 'e-hentai.org',
                path   => '/'
            )
        );


    } else {
        $logger->info("没有提供 Cookies，返回空的 UserAgent。");
    }

    return $ua;

}

1;
