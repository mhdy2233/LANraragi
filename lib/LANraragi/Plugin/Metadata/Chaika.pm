package LANraragi::Plugin::Metadata::Chaika;

use strict;
use warnings;

use URI::Escape;
use Mojo::UserAgent;
use Mojo::DOM;
use LANraragi::Utils::Logging qw(get_plugin_logger);

my $chaika_url = "https://panda.chaika.moe";

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name        => "Chaika.moe",
        type        => "metadata",
        namespace   => "trabant",
        author      => "Difegue",
        version     => "2.3.1",
        description =>
          "在 chaika.moe 上搜索与你的档案匹配的标签。首先尝试使用缩略图，如果失败，则回退到默认的文本搜索。",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA\nB3RJTUUH4wYCFQocjU4r+QAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUH\nAAAEZElEQVQ4y42T3WtTdxzGn/M7J+fk5SRpTk7TxMZkXU84tTbVNrUT3YxO7HA4pdtQZDe7cgx2\ns8vBRvEPsOwFYTDYGJUpbDI2wV04cGXCGFLonIu1L2ptmtrmxeb1JDkvv121ZKVze66f74eH7/f5\nMmjRwMCAwrt4/9KDpflMJpPHvyiR2DPcJklJ3TRDDa0xk36cvrm8vDwHAAwAqKrqjjwXecPG205w\nHBuqa9rk77/d/qJYLD7cCht5deQIIczbgiAEKLVAKXWUiqVV06Tf35q8dYVJJBJem2A7Kwi2nQzD\nZig1CG93+PO5/KN6tf5NKpVqbsBUVVVFUUxwHJc1TXNBoxojS7IbhrnLMMx9pVJlBqFQKBKPxwcB\nkJYgjKIo3QCE1nSKoghbfJuKRqN2RVXexMaQzWaLezyeEUEQDjscjk78PxFFUYRkMsltJgGA3t7e\nyMLCwie6rr8iCILVbDbvMgwzYRjGxe0o4XC4s1AoHPP5fMP5/NNOyzLKAO6Ew+HrDADBbre/Ryk9\nnzx81FXJNlEpVpF+OqtpWu2MpmnXWmH9/f2umZmZi4cOHXnLbILLzOchhz1YerJAs9m1GwRAg2GY\nh7GYah488BJYzYW+2BD61AFBlmX/1nSNRqN9//792ujoaIPVRMjOKHoie3DytVGmp2fXCAEAjuMm\nu7u7Umosho6gjL/u/QHeEgvJZHJ2K/D+/fuL4+PjXyvPd5ldkShy1UXcmb4DnjgQj/fd5gDA6/XS\nYCAwTwh9oT3QzrS1+VDVi+vd3Tsy26yQVoFF3dAXJVmK96p9EJ0iLNOwKKU3CQCk0+lSOpP5WLDz\nF9Q9kZqyO0SloOs6gMfbHSU5NLRiUOuax2/HyZPHEOsLw2SbP83eu/fLxrkNp9P554XxCzVa16MC\n7+BPnTk9cfmH74KJE8nmga7Xy5JkZ8VKifGIHpoBb1VX8hNTd3/t/7lQ3OeXfFPvf/jBRw8ezD/a\n7M/aWq91cGgnJaZ2VcgSdnV1XRNNd3vAoBVVYusmnEQS65hfgSG6c+zy3Kre7nF/KrukcMW0Zg8O\nD08DoJutDxxOEb5IPUymwrq8ft1gLKfkFojkkRxemERCAQUACPFWRazYLJcrFGwQhyufbQQ7rFpy\nLMkCwGZC34qPIuwp+XPOjBFwazQ/txrdFS2GGS/Xuj+pUKLGk1Kjvlded3s72lyGW+PLbGVcmrAA\ngN0wTk1NWYODg9XOKltGtpazi5GigzroUnHN5nUHG1ylRsG7rDXHmnEpu4CeEtEKkqNc6QqlLc/M\n8uT5lLH5eq0aGxsju1O7GQB498a5s/0x9dRALPaQEDZnYwnhWJtMCCNrjeb0UP34Z6e/PW22zjPP\n+vwXBwfPvbw38XnXjk7GsiwKAIQQhjAMMrlsam45d+zLH6/8o6vkWcBcrXbVKQhf6bpucCwLjmUB\nSmmhXC419eblrbD/TAgAkUjE987xE0c7ZDmk66ajUCnq+cL63fErl25s5/8baQPaWLhx6goAAAAA\nSUVORK5CYII=",
        parameters => [
            { type => "bool", desc => "如果可用，添加以下标签：下载 URL、画廊 ID、类别、时间戳" },
            {   type => "bool",
                desc =>
                  "将没有命名空间的标签添加到 'other:' 命名空间中，以镜像 E-H 的所有标签命名空间行为"
            },
            {   type => "string",
                desc => "添加自定义的 'source:' 标签到你的档案中。示例：chaika。如果为空则不添加标签"
            },
            {   type => "bool",
                desc => "在可用时保存原始标题，而不是英文或罗马化标题"
            }
        ],
        oneshot_arg => "Chaika 画廊或档案 URL（将把匹配的标签附加到你的档案中）"
    );

}

# 必须实现的函数，返回一个标签哈希
sub get_tags {

    shift;
    my $lrr_info = shift;                                       # 全局信息哈希
    my ( $addextra, $addother, $addsource, $jpntitle ) = @_;    # 插件参数

    my $logger   = get_plugin_logger();
    my $newtags  = "";
    my $newtitle = "";

    # 解析给定的链接以查看是否可以提取类型和 ID
    my $oneshotarg = $lrr_info->{oneshot_param};
    if ( $oneshotarg =~ /https?:\/\/panda\.chaika\.moe\/(gallery|archive)\/([0-9]*)\/?.*/ ) {
        ( $newtags, $newtitle ) = tags_from_chaika_id( $1, $2, $addextra, $addother, $addsource, $jpntitle );
    } else {

        # 首先尝试 SHA-1 反向搜索
        $logger->info( "使用缩略图哈希 " . $lrr_info->{thumbnail_hash} );
        ( $newtags, $newtitle ) = tags_from_sha1( $lrr_info->{thumbnail_hash}, $addextra, $addother, $addsource, $jpntitle );

        # 如果失败，尝试文本搜索
        if ( $newtags eq "" ) {
            $logger->info("没有结果，回退到文本搜索。");
            ( $newtags, $newtitle ) =
              search_for_archive( $lrr_info->{archive_title}, $lrr_info->{existing_tags}, $addextra, $addother, $addsource, $jpntitle );
        }
    }

    if ( $newtags eq "" ) {
        $logger->info("未找到匹配的 Chaika 档案！");
        return ( error => "未找到匹配的 Chaika 档案！" );
    } else {
        $logger->info("将以下标签发送到 LRR: $newtags");

        # 返回包含新元数据的哈希
        return ( tags => $newtags, title => $newtitle );
    }

}

######
## Chaika 特定方法
######

# search_for_archive
# 使用 Chaika 的 HTML 搜索来找到匹配的档案 ID
sub search_for_archive {

    my $logger = get_plugin_logger();
    my ( $title, $tags, $addextra, $addother, $addsource, $jpntitle ) = @_;

    # 自动将标题转为小写以获得更好的结果
    $title = lc($title);

    # 去除破坏搜索的连字符和撇号
    $title =~ s/-|'/ /g;

    my $URL = "$chaika_url/jsearch/?gsp&title=" . uri_escape_utf8($title) . "&tags=";

    # 如果标签中包含 language:english，则添加语言标签
    if ( $tags =~ /.*language:\s?english,*.*/gi ) {
        $URL = $URL . uri_escape_utf8("language:english") . "+";
    }

    $logger->debug("调用 $URL");
    my $ua  = Mojo::UserAgent->new;
    my $res = $ua->get($URL)->result;

    my $textrep = $res->body;
    $logger->debug("Chaika API 返回的 JSON: $textrep");

    my ( $chaitags, $chaititle ) = parse_chaika_json( $res->json->{"galleries"}->[0], $addextra, $addother, $addsource, $jpntitle );

    return ( $chaitags, $chaititle );
}

# 使用 jsearch API 获取最好的 JSON 数据
sub tags_from_chaika_id {

    my ( $type, $ID, $addextra, $addother, $addsource, $jpntitle ) = @_;

    my $json = get_json_from_chaika( $type, $ID );
    return parse_chaika_json( $json, $addextra, $addother, $addsource, $jpntitle );
}

# tags_from_sha1
# 使用 Chaika 的 SHA-1 搜索来处理首个页面哈希
sub tags_from_sha1 {

    my ( $sha1, $addextra, $addother, $addsource, $jpntitle ) = @_;

    my $logger = get_plugin_logger();

    # jsearch API 立即返回 JSON。
    # JSON 是一个包含多个档案对象的数组。
    # 我们只取第一个。
    my $json_by_sha1 = get_json_from_chaika( 'sha1', $sha1 );
    return parse_chaika_json( $json_by_sha1->[0], $addextra, $addother, $addsource, $jpntitle );
}

# 调用 Chaika 的 API
sub get_json_from_chaika {

    my ( $type, $value ) = @_;

    my $logger = get_plugin_logger();
    my $URL    = "$chaika_url/jsearch/?$type=$value";
    my $ua     = Mojo::UserAgent->new;
    my $res    = $ua->get($URL)->result;

    if ( $res->is_error ) {
        return;
    }
    my $textrep = $res->body;
    $logger->debug("Chaika API 返回的 JSON: $textrep");

    return $res->json;
}

# 解析从 Chaika API 获得的 JSON 以获取标签
sub parse_chaika_json {

    my ( $json, $addextra, $addother, $addsource, $jpntitle ) = @_;
    my $tags = $json->{"tags"} || ();
    foreach my $tag (@$tags) {

        # 将下划线替换为空格
        $tag =~ s/_/ /g;

        # 如果没有命名空间，则添加 'other' 命名空间
        if ( $addother && index( $tag, ":" ) == -1 ) {
            $tag = "other:" . $tag;
        }
    }

    my $category  = lc $json->{"category"};
    my $download  = $json->{"download"} ? $json->{"download"} : $json->{"archives"}->[0]->{"link"};
    my $gallery   = $json->{"gallery"}  ? $json->{"gallery"}  : $json->{"id"};
    my $timestamp = $json->{"posted"};
    if ( $tags && $addextra ) {
        if ( $category ne "" ) {
            push( @$tags, "category:" . $category );
        }
        if ( $download ne "" ) {
            push( @$tags, "download:" . $download );
        }
        if ( $gallery ne "" ) {
            push( @$tags, "gallery:" . $gallery );
        }
        if ( $timestamp ne "" ) {
            push( @$tags, "timestamp:" . $timestamp );
        }
    }

    if ( $gallery && $gallery ne "" ) {

        # 添加自定义源，但仅在找到画廊时添加
        if ( $addsource && $addsource ne "" ) {
            push( @$tags, "source:" . $addsource );
        }

        my $title = $jpntitle ? $json->{"title_jpn"} : $json->{"title"};
        if ( $title eq "" && $jpntitle ) {
            $title = $json->{"title"};
        }
        return ( join( ', ', @$tags ), $title );
    } else {
        return "";
    }
}

1;
