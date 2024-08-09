package LANraragi::Plugin::Login::EHentai;
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
        name      => "E-Hentai",  # 插件名称
        type      => "login",     # 插件类型：登录
        namespace => "ehlogin",   # 命名空间
        author    => "Difegue",   # 作者
        version   => "2.3",       # 版本号
        description =>
          "处理 E-H 的登录。如果你有可以访问受限内容或 Exhentai 的帐户，在此处添加凭据将使更多的归档可供解析。",  # 插件描述
        parameters => [
            { type => "int",    desc => "ipb_member_id cookie" },  # 参数：ipb_member_id cookie
            { type => "string", desc => "ipb_pass_hash cookie" },   # 参数：ipb_pass_hash cookie
            { type => "string", desc => "star cookie（可选，如果存在你可以查看受限内容而无需使用 Exhentai）" },
            { type => "string", desc => "igneous cookie（可选，如果存在你可以在不使用欧洲和美洲 IP 的情况下查看 Exhentai）" }
        ]
    );

}

# 登录插件必须实现的函数
# 仅返回一个 Mojo::UserAgent 对象！
sub do_login {

    # 登录插件仅接收用户输入的参数。
    shift;
    my ( $ipb_member_id, $ipb_pass_hash, $star ,$igneous ) = @_;
    return get_user_agent( $ipb_member_id, $ipb_pass_hash, $star ,$igneous );
}

# get_user_agent(ipb cookies)
# 尝试创建一个可以访问 E-Hentai 的 Mojo::UserAgent 对象。
# 返回创建的 UA 对象。
sub get_user_agent {

    my ( $ipb_member_id, $ipb_pass_hash, $star, $igneous ) = @_;

    my $logger = get_logger( "E-Hentai 登录", "插件" );
    my $ua     = Mojo::UserAgent->new;

    if ( $ipb_member_id ne "" && $ipb_pass_hash ne "" ) {
        $logger->info("提供的 Cookies ($ipb_member_id $ipb_pass_hash $star $igneous)！");

        # 设置所需的 Cookie 在两个域名中
        # 它们应该转换为包含生成的 igneous 值的 Exhentai Cookies
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

        # 跳过“冒犯性警告”屏幕，以便下载脚本可以轻松检索此类画廊的归档 gID。
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
        $logger->info("未提供 Cookies，返回空的 UserAgent。");
    }

    return $ua;

}

1;
