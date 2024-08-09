package LANraragi::Plugin::Metadata::nHentai;

use utf8;
use strict;
use warnings;

# 插件可以自由使用系统中已安装的所有 Perl 包
# 尽量限制使用已经安装在 LRR 上的包（见 tools/cpanfile），以避免最终用户需要额外安装。
use URI::Escape;
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;
use File::Basename;

# 你也可以使用 LRR 内部 API。
use LANraragi::Model::Plugins;
use LANraragi::Utils::Logging qw(get_plugin_logger);

# 关于插件的元信息。
sub plugin_info {

    return (
        # 标准元数据
        name        => "nHentai",       # 插件名称
        type        => "metadata",      # 插件类型：元数据
        namespace   => "nhplugin",       # 命名空间
        login_from  => "nhentaicfbypass",  # 从哪个登录插件获取登录信息
        author      => "Difegue and others", # 作者
        version     => "1.8.0",         # 版本号
        description => "搜索 nHentai 中与您的档案匹配的标签。<br>支持从格式为 \"{Id} Title\" 的文件中读取 ID，如果没有，则尝试搜索匹配的画廊。<br><i class='fa fa-exclamation-circle'></i> 如果档案中存在 source: 标签，本插件将使用该标签。",
        icon        => "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAIAAAAC64paAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA\nB3RJTUUH4wYCFA8s1yKFJwAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUH\nAAACL0lEQVQ4y6XTz0tUURQH8O+59773nLFcaGWTk4UUVCBFiJs27VxEQRH0AyRo4x8Q/Qtt2rhr\nU6soaCG0KYKSwIhMa9Ah+yEhZM/5oZMG88N59717T4sxM8eZCM/ycD6Xwznn0pWhG34mh/+PA8mk\n8jO5heziP0sFYwfgMDFQJg4IUjmquSFGG+OIlb1G9li5kykgTgvzSoUCaIYlo8/Igcjpj5wOkARp\n8AupP0uzJLijCY4zzoXOxdBLshAgABr8VOp7bpAXDEI7IBrhdksnjNr3WzI4LaIRV9fk2iAaYV/y\nA1dPiYjBAALgpQxnhV2XzTCAGWGeq7ACBvCdzKQyTH+voAm2hGlpcmQt2Bc2K+ymAhWPxTzPDQLt\nOKo1FiNBQaArq9WNRQwEgKl7XQ1duzSRSn/88vX0qf7DPQddx1nI5UfHxt+m0sLYPiP3shRAG8MD\nok1XEEXR/EI2ly94nrNYWG6Nx0/2Hp2b94dv34mlZge1e4hVCJ4jc6tl9ZP803n3/i4lpdyzq2N0\n7M3DkSeF5ZVYS8v1qxcGz5+5eey4nPDbmGdE9FpGeWErVNe2tTabX3r0+Nk3PwOgXFkdfz99+exA\nMtFZITEt9F23mpLG0hYTVQCKpfKPlZ/rqWKpYoAPcTmpginW76QBbb0OBaBaDdjaDbNlJmQE3/d0\nMYoaybU9126oPkrEhpr+U2wjtoVVGBowkslEsVSupRKdu0Mduq7q7kqExjSS3V2dvwDLavx0eczM\neAAAAABJRU5ErkJggg==",
        parameters  => [],
        oneshot_arg => "nHentai 画廊 URL（将把与此确切画廊匹配的标签附加到您的档案）"
    );

}

# 插件必须实现的函数
sub get_tags {

    shift;
    my $lrr_info = shift;                      # 全局信息哈希
    my $ua       = $lrr_info->{user_agent};    # 从登录插件获取的 UserAgent

    my $logger = get_plugin_logger();

    # 执行你的魔法 - 你可以在下面创建子例程以更好地组织代码
    my $galleryID = "";

    # 快速正则表达式从提供的 URL 或 source 标签中获取 nh 画廊 ID。
    if ( $lrr_info->{oneshot_param} =~ /.*\/g\/([0-9]+).*/ ) {
        $galleryID = $1;
        $logger->debug("跳过搜索，使用 oneshot 参数中的画廊 $galleryID");
    } elsif ( $lrr_info->{existing_tags} =~ /.*source:\s*(?:https?:\/\/)?nhentai\.net\/g\/([0-9]*).*/gi ) {

        # 匹配 URL Scheme 如 'https://' 仅用于向后兼容目的。
        $galleryID = $1;
        $logger->debug("跳过搜索，使用 source 标签中的画廊 $galleryID");
    } else {

        # 如果用户没有指定 URL，通过手动获取画廊 ID
        $galleryID = get_gallery_id_from_title( $lrr_info->{file_path}, $ua );
    }

    # 我们是否检测到 nHentai 画廊？
    if ( defined $galleryID ) {
        $logger->debug("检测到的 nHentai 画廊 ID 是 $galleryID");
    } else {
        $logger->info("没有找到匹配的 nHentai 画廊！");
        return ( error => "没有找到匹配的 nHentai 画廊！" );
    }

    # 如果没有找到令牌，返回包含错误消息的哈希。
    # LRR 将显示该错误给客户端。
    if ( $galleryID eq "" ) {
        $logger->info("没有找到匹配的 nHentai 画廊！");
        return ( error => "没有找到匹配的 nHentai 画廊！" );
    }

    my %hashdata = get_tags_from_NH( $galleryID, $ua );

    $logger->info( "发送到 LRR 的标签：" . $hashdata{tags} );

    # 返回包含新元数据的哈希 - 它将被集成到 LRR 中。
    return %hashdata;
}

######
## NH 特定方法
######

# 使用网站的搜索功能查找画廊并返回其内容。
sub get_gallery_dom_by_title {

    my ( $title, $ua ) = @_;

    my $logger = get_plugin_logger();

    # 去掉破坏搜索的连字符和撇号
    $title =~ s/-|'/ /g;

    my $URL = "https://nhentai.net/search/?q=" . uri_escape_utf8($title);

    $logger->debug("使用 URL $URL 在 nHentai 上进行搜索。");

    my $res = $ua->get($URL)->result;
    $logger->debug( "获取响应 " . $res->body );

    if ( $res->is_error ) {
        return;
    }

    return $res->dom;
}

sub get_gallery_id_from_title {

    my ( $file, $ua ) = @_;
    my ( $title, $filepath, $suffix ) = fileparse( $file, qr/\.[^.]*/ ); 

    my $logger = get_plugin_logger();

    if ( $title =~ /\{(\d*)\}.*$/gm ) {
        $logger->debug("从文件中获得 $1");
        return $1;
    }

    my $dom = get_gallery_dom_by_title( $title, $ua );

    if ($dom) {

        # 获取搜索结果中的第一个画廊 URL
        my $gURL =
          ( $dom->at('.cover') )
          ? $dom->at('.cover')->attr('href')
          : "";

        $logger->debug("从解析中获得 $gURL");
        if ( $gURL =~ /\/g\/(\d*)\//gm ) {
            return $1;
        }
    }

    return;
}

# 从 NH 获取 HTML 页面
sub get_html_from_NH {

    my ( $gID, $ua ) = @_;

    my $URL = "https://nhentai.net/g/$gID/";

    my $res = $ua->get($URL)->result;

    if ( $res->is_error ) {
        my $code = $res->code;
        return "error ($code)";
    }

    return $res->body;
}

# 查找 HTML 中的元数据 JSON 并将其转换为对象
# 它位于 N.gallery JS 对象下。
sub get_json_from_html {

    my ($html) = @_;

    my $logger = get_plugin_logger();

    my $jsonstring = "{}";
    if ( $html =~ /window\._gallery.*=.*JSON\.parse\((.*)\);/gmi ) {
        $jsonstring = $1;
    }

    $logger->debug("尝试的 JSON：$jsonstring");

    # nH 现在提供的 JSON 具有 \uXXXX 转义字符。
    # 第一次 decode_json 解码这些字符，但仍然输出为字符串。
    # 第二次解码将该字符串正确地转换为对象，以便我们可以将其作为哈希利用。
    my $json = decode_json $jsonstring;
    $json = decode_json $json;

    return $json;
}

sub get_tags_from_json {

    my ($json) = @_;

    my @json_tags = @{ $json->{"tags"} };
    my @tags      = ();

    foreach my $tag (@json_tags) {

        my $namespace = $tag->{"type"};
        my $name      = $tag->{"name"};

        if ( $namespace eq "tag" ) {
            push( @tags, $name );
        } else {
            push( @tags, "$namespace:$name" );
        }
    }

    return @tags;
}

sub get_title_from_json {
    my ($json) = @_;
    return $json->{"title"}{"pretty"};
}

sub get_tags_from_NH {

    my ( $gID, $ua ) = @_;

    my %hashdata = ( tags => "" );

    my $html = get_html_from_NH( $gID, $ua );

    # 如果字符串以 "error" 开头，我们无法从 NH 获取数据。
    if ( $html =~ /^error/ ) {
        return ( error => "从 nHentai 获取画廊时出错！ ($html)" );
    }

    my $json = get_json_from_html($html);

    if ($json) {
        my @tags = get_tags_from_json($json);
        push( @tags, "source:nhentai.net/g/$gID" ) if ( @tags > 0 );

        # 使用 NH 的 "pretty" 名称（去掉我们已经拥有的多余数据，如 (Event)[Artist] 等）
        $hashdata{tags}  = join( ', ', @tags );
        $hashdata{title} = get_title_from_json($json);
    }

    return %hashdata;
}

1;
