package LANraragi::Plugin::Metadata::EHentai;

use utf8;    # 添加这一行以支持 UTF-8 编码
use strict;
use warnings;
no warnings 'uninitialized';

# 插件可以自由使用系统上已安装的所有 Perl 包
# 但请尽量限制在 LRR 已安装的包（参见 tools/cpanfile）范围内，以避免最终用户额外安装。
use URI::Escape;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw(html_unescape);
use Mojo::UserAgent;

# 您还可以在适当的时候使用 LRR 内部 API。
use LANraragi::Model::Plugins;
use LANraragi::Utils::Logging qw(get_plugin_logger);

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name        => "E-Hentai",
        type        => "metadata",
        namespace   => "ehplugin",
        login_from  => "ehlogin",
        author      => "Difegue 等",
        version     => "2.5.2",
        description =>
          "在 g.e-hentai 上搜索与您的归档匹配的标签。<br/><i class='fa fa-exclamation-circle'></i> 如果归档存在 source: 标签，此插件将使用该标签。",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI\nWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4wYBFg0JvyFIYgAAAB1pVFh0Q29tbWVudAAAAAAAQ3Jl\nYXRlZCB3aXRoIEdJTVBkLmUHAAAEo0lEQVQ4y02UPWhT7RvGf8/5yMkxMU2NKaYIFtKAHxWloYNU\ncRDeQTsUFPwAFwUHByu4ODq4Oghdiri8UIrooCC0Lx01ONSKfYOioi1WpWmaxtTm5PTkfNzv0H/D\n/9oeePjdPNd13Y8aHR2VR48eEUURpmmiaRqmaXbOAK7r4vs+IsLk5CSTk5P4vo9hGIgIsViMra0t\nCoUCRi6XY8+ePVSrVTRN61yybZuXL1/y7t078vk8mUyGvXv3cuLECWZnZ1lbW6PdbpNIJHAcB8uy\nePr0KYZlWTSbTRKJBLquo5TCMAwmJia4f/8+Sini8Ti1Wo0oikin09i2TbPZJJPJUK/XefDgAefO\nnWNlZQVD0zSUUvi+TxAE6LqOrut8/fqVTCaDbdvkcjk0TSOdTrOysoLrujiOw+bmJmEYMjAwQLVa\nJZVKYXR1ddFut/F9H9M0MU0T3/dZXV3FdV36+/vp7u7m6NGj7Nq1i0qlwuLiIqVSib6+Pubn5wGw\nbZtYLIaxMymVSuH7PpZlEUURSina7TZBEOD7Pp8/fyYMQ3zfZ25ujv3795NOp3n48CE9PT3ouk4Q\nBBi/fv3Ctm0cx6Grq4utrS26u7sREQzDIIoifv78SU9PD5VKhTAMGRoaYnV1leHhYa5evUoQBIRh\niIigiQhRFKHrOs1mE9u2iaKIkydPYhgGAKZp8v79e+LxOPl8Htd1uXbtGrdv3yYMQ3ZyAODFixeb\nrVZLvn//Lq7rSqVSkfX1dREROXz4sBw/flyUUjI6OipXrlyRQ4cOSbPZlCiKxHVdCcNQHMcRz/PE\ndV0BGL53756sra1JrVaT9fV1cRxHRESGhoakr69PUqmUvHr1SsrlsuzI931ptVriuq78+fNHPM+T\nVqslhoikjh075p09e9ba6aKu6/T39zM4OMjS0hIzMzM0Gg12794N0LEIwPd9YrEYrusShiEK4Nmz\nZ41yudyVy+XI5/MMDAyQzWap1+tks1lEhIWFBQqFArZto5QiCAJc1+14t7m5STweRwOo1WoSBAEj\nIyMUi0WSySQiQiqV6lRoYWGhY3673e7sfRAEiAjZbBbHcbaBb9++5cCBA2SzWZLJJLZt43kesViM\nHX379g1d1wnDsNNVEQEgCAIajQZ3797dBi4tLWGaJq7rYpompVKJmZkZ2u12B3j58mWUUmiahoiw\nsbFBEASdD2VsbIwnT55gACil+PHjB7Ozs0xPT/P7929u3ryJZVmEYUgYhhQKBZRSiAie52EYBkop\nLMvi8ePHTE1NUSwWt0OZn5/3hoeHzRs3bqhcLseXL1+YmJjowGzbRtO07RT/F8jO09+8ecP58+dJ\nJBKcPn0abW5uThWLRevOnTv/Li4u8vr1a3p7e9E0jXg8zsePHymVSnz69Kmzr7quY9s2U1NTXLp0\nCc/zOHLkCPv27UPxf6rX63+NjIz8IyKMj48zPT3NwYMHGRwcpLe3FwARodVqcf36dS5evMj4+DhB\nEHDmzBkymQz6DqxSqZDNZr8tLy//DYzdunWL5eVlqtUqHz58IJVKkUwmaTQalMtlLly4gIjw/Plz\nTp06RT6fZ2Njg/8AqMV7tO07rnsAAAAASUVORK5CYII=",
        parameters => [
            { type => "string", desc => "在搜索中强制使用的语言（由于 EH 限制，日语将无法使用）" },
            { type => "bool",   desc => "优先使用缩略图进行搜索（若失败则回退到标题）" },
            { type => "bool",   desc => "使用标题中的 gID 进行搜索（若失败则回退到标题）" },
            { type => "bool",   desc => "使用 ExHentai（启用此选项可在无星标 Cookie 的情况下搜索被 fjorded 的内容）" },
            {   type => "bool",
                desc => "在可用的情况下保存原始标题，而不是英文或罗马化的标题"
            },
            { type => "bool", desc => "获取额外的时间戳（发布时间）和上传者元数据" },
            { type => "bool", desc => "仅搜索已删除的图库" },

        ],
        oneshot_arg => "E-H 图库 URL（将匹配此精确图库的标签附加到您的归档）",
        cooldown    => 4
    );

}

# 必须由您的插件实现的函数
sub get_tags {

    shift;
    my $lrr_info = shift;                                                                               # 全局信息哈希
    my $ua       = $lrr_info->{user_agent};
    my ( $lang, $usethumbs, $search_gid, $enablepanda, $jpntitle, $additionaltags, $expunged ) = @_;    # 插件参数

    # 使用记录器输出状态 - 它们将被传递到专用日志文件并写入 STDOUT。
    my $logger = get_plugin_logger();

    # 在此处进行处理 - 您可以在下面创建子例程以更好地组织代码
    my $gID    = "";
    my $gToken = "";
    my $domain = ( $enablepanda ? 'https://exhentai.org' : 'https://e-hentai.org' );
    my $hasSrc = 0;

    # 快速正则表达式，从提供的 URL 或 source 标签中获取 E-H 归档 ID
    if ( $lrr_info->{oneshot_param} =~ /.*\/g\/([0-9]*)\/([0-z]*)\/*.*/ ) {
        $gID    = $1;
        $gToken = $2;
        $logger->debug("跳过搜索，使用来自 oneshot 参数的图库 $gID / $gToken");
    } elsif ( $lrr_info->{existing_tags} =~ /.*source:\s*(?:https?:\/\/)?e(?:x|-)hentai\.org\/g\/([0-9]*)\/([0-z]*)\/*.*/gi ) {
        $gID    = $1;
        $gToken = $2;
        $hasSrc = 1;
        $logger->debug("跳过搜索，使用来自 source 标签的图库 $gID / $gToken");
    } else {

        # 如果没有用户参数，则为 EH 的文本搜索构建 URL
        ( $gID, $gToken ) = &lookup_gallery(
            $lrr_info->{archive_title},
            $lrr_info->{existing_tags},
            $lrr_info->{thumbnail_hash},
            $ua, $domain, $lang, $usethumbs, $search_gid, $expunged
        );
    }

    # 如果发生错误，返回包含错误消息的哈希。
    # LRR 将向客户端显示该错误。
    # 使用 GToken 来存储错误代码 - 这不是最干净的方法，但很方便
    if ( $gID eq "" ) {

        if ( $gToken ne "" ) {
            $logger->error($gToken);
            return ( error => $gToken );
        }

        $logger->info("未找到匹配的 EH 图库！");
        return ( error => "未找到匹配的 EH 图库！" );
    } else {
        $logger->debug("EH API 令牌为 $gID / $gToken");
    }

    my ( $ehtags, $ehtitle ) = &get_tags_from_EH( $ua, $gID, $gToken, $jpntitle, $additionaltags );
    my %hashdata = ( tags => $ehtags );

    # 如果可能/适用，添加 source URL 和标题
    if ( $hashdata{tags} ne "" ) {

        if ( !$hasSrc ) { $hashdata{tags} .= ", source:" . ( split( '://', $domain ) )[1] . "/g/$gID/$gToken"; }
        $hashdata{title} = $ehtitle;
    }

    # 返回包含新元数据的哈希 - 它将被集成到 LRR 中。
    return %hashdata;
}

######
## EH 特定方法
######

sub lookup_gallery {

    my ( $title, $tags, $thumbhash, $ua, $domain, $defaultlanguage, $usethumbs, $search_gid, $expunged ) = @_;
    my $logger = get_plugin_logger();
    my $URL    = "";

    # 缩略图反向图像搜索
    if ( $thumbhash ne "" && $usethumbs ) {

        $logger->info("启用反向图像搜索，正在尝试。");

        # 使用图像 SHA 哈希进行搜索
        $URL = $domain . "?f_shash=" . $thumbhash . "&fs_similar=on&fs_covers=on";

        $logger->debug("使用 URL $URL（归档缩略图哈希）");

        my ( $gId, $gToken ) = &ehentai_parse( $URL, $ua );

        if ( $gId ne "" && $gToken ne "" ) {
            return ( $gId, $gToken );
        }
    }

    # 如果标题名称中存在 gID，则使用它进行搜索
    my ($title_gid) = $title =~ /\[([0-9]+)\]/g;
    if ( $search_gid && $title_gid ) {
        $URL = $domain . "?f_search=" . uri_escape_utf8("gid:$title_gid");

        $logger->debug("找到 gID: $title_gid，使用 URL $URL（来自归档标题的 gID）");

        my ( $gId, $gToken ) = &ehentai_parse( $URL, $ua );

        if ( $gId ne "" && $gToken ne "" ) {
            return ( $gId, $gToken );
        }
    }

    # 常规文本搜索（高级选项：禁用默认过滤器：语言、上传者、标签）
    $URL = $domain . "?advsearch=1&f_sfu=on&f_sft=on&f_sfl=on" . "&f_search=" . uri_escape_utf8( qw(") . $title . qw(") );

    my $has_artist = 0;

    # 如果 OG 标签中存在 artist 标签（且仅包含 ASCII 字符），则添加
    if ( $tags =~ /.*artist:\s?([^,]*),*.*/gi ) {
        my $artist = $1;
        if ( $artist =~ /^[\x00-\x7F]*$/ ) {
            $URL        = $URL . "+" . uri_escape_utf8("artist:$artist");
            $has_artist = 1;
        }
    }

    # 如果定义了语言覆盖，则添加
    if ( $defaultlanguage ne "" ) {
        $URL = $URL . "+" . uri_escape_utf8("language:$defaultlanguage");
    }

    # 如果启用了选项，则搜索已删除的图库
    if ($expunged) {
        $URL = $URL . "&f_sh=on";
    }

    $logger->debug("使用 URL $URL（归档标题）");
    return &ehentai_parse( $URL, $ua );
}

# ehentai_parse(URL, UA)
# 在 e- 或 exhentai 上执行远程搜索，并返回与找到的图库匹配的 ID/令牌。
sub ehentai_parse() {

    my ( $url, $ua ) = @_;

    my $logger = get_plugin_logger();

    my ( $dom, $error ) = search_gallery( $url, $ua );
    if ($error) {
        return ( "", $error );
    }

    my $gID    = "";
    my $gToken = "";

    eval {
        # 获取搜索结果的第一行
        # 类名为 "glink" 的元素由包含图库链接的 <a> 标签作为父元素。
        # 这在 Minimal、Minimal+ 和 Compact 模式下均有效，应该足够了。
        my $firstgal = $dom->at(".glink")->parent->attr('href');

        # EH 链接看起来像 xhentai.org/g/{gallery id}/{gallery token}
        my $url    = ( split( 'hentai.org/g/', $firstgal ) )[1];
        my @values = ( split( '/',             $url ) );

        $gID    = $values[0];
        $gToken = $values[1];
    };

    if ( index( $dom->to_string, "You are opening" ) != -1 ) {
        my $rand = 15 + int( rand( 51 - 15 ) );
        $logger->info("由于 EH 过多请求警告，暂停 $rand 秒");
        sleep($rand);
    }

    # 返回结果
    return ( $gID, $gToken );
}

sub search_gallery {

    my ( $url, $ua ) = @_;
    my $logger = get_plugin_logger();

    my $res = $ua->max_redirects(5)->get($url)->result;

    if ( index( $res->body, "Your IP address has been" ) != -1 ) {
        return ( "", "由于过多页面加载，暂时被 EH 禁止。" );
    }

    return ( $res->dom, undef );
}

# get_tags_from_EH(userAgent, gID, gToken, jpntitle, additionaltags)
# 使用给定的 JSON 执行 e-hentai API 请求，并返回标签和标题。
sub get_tags_from_EH {

    my ( $ua, $gID, $gToken, $jpntitle, $additionaltags ) = @_;
    my $uri = 'https://api.e-hentai.org/api.php';

    my $logger = get_plugin_logger();

    my $jsonresponse = get_json_from_EH( $ua, $gID, $gToken );

    # 如果发生错误（无响应），则返回空字符串。
    if ( !$jsonresponse ) {
        return ( "", "" );
    }

    my $data    = $jsonresponse->{"gmetadata"};
    my @tags    = @{ @$data[0]->{"tags"} };
    my $ehtitle = @$data[0]->{ ( $jpntitle ? "title_jpn" : "title" ) };
    if ( $ehtitle eq "" && $jpntitle ) {
        $ehtitle = @$data[0]->{"title"};
    }
    my $ehcat = lc @$data[0]->{"category"};

    push( @tags, "category:$ehcat" );
    if ($additionaltags) {
        my $ehuploader  = @$data[0]->{"uploader"};
        my $ehtimestamp = @$data[0]->{"posted"};
        push( @tags, "uploader:$ehuploader" );
        push( @tags, "timestamp:$ehtimestamp" );
    }

    # 反转义从 API 接收到的标题，因为它可能包含一些 HTML 字符
    $ehtitle = html_unescape($ehtitle);

    my $ehtags = join( ', ', @tags );
    $logger->info("向 LRR 发送以下标签：$ehtags");

    return ( $ehtags, $ehtitle );
}

sub get_json_from_EH {

    my ( $ua, $gID, $gToken ) = @_;
    my $uri = 'https://api.e-hentai.org/api.php';

    my $logger = get_plugin_logger();

    # 执行请求
    my $rep = $ua->post(
        $uri => json => {
            method    => "gdata",
            gidlist   => [ [ $gID, $gToken ] ],
            namespace => 1
        }
    )->result;

    my $textrep = $rep->body;
    $logger->debug("E-H API 返回的 JSON：$textrep");

    my $jsonresponse = $rep->json;
    if ( exists $jsonresponse->{"error"} ) {
        return;
    }

    return $jsonresponse;
}

1;
