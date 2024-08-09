package LANraragi::Plugin::Metadata::Pixiv;

use utf8;
use strict;
use warnings;

# 插件可以自由使用系统上已安装的所有 Perl 包
# 但请尽量限制使用已为 LRR 安装的包（见 tools/cpanfile），以避免用户需要额外安装。
use Mojo::DOM;
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;

use Time::Piece;
use Time::Local;

# 你也可以使用 LRR 包（如果适用）。
# 所有包都可以使用，但只有 Utils 包中显式导出的函数在版本间受到支持。
# 其他一切被认为是内部 API 可能在版本间被破坏/重命名。
use LANraragi::Model::Plugins;
use LANraragi::Utils::Logging qw(get_plugin_logger);

# 插件的元信息
sub plugin_info {

    return (
        # 标准元数据
        name        => "Pixiv",
        type        => "metadata",
        namespace   => "pixivmetadata",
        login_from  => "pixivlogin",
        author      => "psilabs-dev",
        version     => "0.1",
        description => "通过艺术作品 ID 获取 Pixiv 艺术作品的元数据。
            <br>支持从以下文件格式提取 ID: \"{Id} Title\" 或 \"pixiv_{Id} Title\"。
            <br>
            <br><i class='fa fa-exclamation-circle'></i> Pixiv 对 API 请求施加了速率限制，过度使用可能会暂停/禁止你的账户。
        ",
        icon        => "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAUABQDAREAAhEBAxEB/8QAGQAAAgMBAAAAAAAAAAAAAAAAAwYABAUH/8QAJBAAAgICAgICAgMAAAAAAAAAAQIDBAUGABESIQcxImETQVH/xAAZAQACAwEAAAAAAAAAAAAAAAADBgACCAX/xAAoEQABBAEDAgYDAQAAAAAAAAABAgMEEQAFITESUQYTFEFhkTJxocH/2gAMAwEAAhEDEQA/ANfRvi3MbpRvZxrlfG4jHQT2J7U35PIsKB5FhjHuRgpHf0B5DsjvmrNV15nTHERwkrcWQABwOo0Co8AE/smjQzIWkeHn9VbXIKghpAUSTyekWQkckgV2G4s4fXNI1LeMkuuarsuQizVgEUYsnTSKG5IB2Iw6SN/GzdevIEE+uxwc3VJmlteqltJLQ/IoUSUjvRAsD3rf4wkHSYOru+khOqDp/ELSAFHtYUaJ9rFfOJFmtPTsy07UTRTQO0ciMOirKeiD+wRzvIWl1IWg2DuP1i642ppZbWKINEfIzpnwOHt5LaaE14QVzqeV/OTyMcRaNQXIUE/0O+gT64q+LKbajuJTZ85virNE7b/6cbvB9uPSWlKpPkO83QsDfa/4MFoFHVNE2jH7tsm54u5Dhplu16OLaSaxbmT2ie0VY18gO2Yj19A8Jq7szVYi4EVhSS4OkqXQSkHk8kk1wB95XRmYWjzG9QlyEqDZ6glFlSiNwOAAL5JPHtiHn8vNsGdyOesoqS5G3LbdV+laRyxA/XvjBEjJhx0R07hAA+hWLU2SqbJckrFFair7N4ClksjjWkbHX7NUzRmKQwyshdD9qej7B/w8u6y09QdSDW4sXR74Np91iy0opsUaJFjtt7ZX4XBZOTJn/9k=",
        # 如果你的插件使用/需要自定义参数，请在此输入其名称。
        # 这个名称将在插件配置中显示在全局参数的输入框旁边，并在归档编辑中显示为一次性参数。
        oneshot_arg => "Pixiv 艺术作品 URL 或插图 ID（例如 pixiv.net/en/artworks/123456 或 123456。）",
        parameters  => [
            { type => 'string', desc => '支持的语言的逗号分隔列表。选项：jp，en。空字符串默认为原始标签（jp）' }
        ],
        cooldown    => 1
    );

}

# 插件需要实现的强制性函数
sub get_tags {

    shift;
    my $lrr_info = shift; # 全局信息哈希，包含 LRR 提供的各种元数据
    my $ua = $lrr_info -> {user_agent};
    my $logger = get_plugin_logger();
    my ( $tag_languages_str ) = @_;

    my $illust_id = find_illust_id( $lrr_info );
    if ($illust_id ne '') {
        $logger -> debug("获取到 Pixiv 插图 ID = $illust_id");

        # 在这里施展你的魔法 - 你可以在下面创建子例程以更好地组织代码
        my %metadata = get_metadata_from_illust_id( $illust_id, $ua , $tag_languages_str );

        # 否则，返回你收集到的标签。
        $logger -> info( "发送以下标签到 LRR: " . $metadata{tags} );
        return %metadata;
    } else {
        $logger -> error( "提取 Pixiv ID 失败！" );
    }

}

######
## Pixiv 特定方法
######

# 将格式化的日期转换为秒级 epoch 时间。
sub _convert_epoch_seconds {
    my ( $formattedDate ) = @_;

    $formattedDate =~ s/(\+\d{2}:\d{2})$//; 
    my $epoch_seconds = Time::Piece -> strptime( $formattedDate, "%Y-%m-%dT%H:%M:%S" ) -> epoch;
    return $epoch_seconds;
}

# 根据搜索语法清理文本：https://sugoi.gitbook.io/lanraragi/basic-operations/searching
sub sanitize {

    my ( $text ) = @_;
    my $sanitized_text = $text;

    # 将非分隔符字符替换为空字符串。
    $sanitized_text =~ s/["?*%\$:]//g;

    # 将下划线替换为空格。
    $sanitized_text =~ s/[_]/ /g;

    # 如果一个连字符前面有空格，则去掉；否则保留。
    $sanitized_text =~ s/ -/ /g;

    if ( $sanitized_text ne $text ) {
        my $logger = get_plugin_logger();
        $logger -> info("\"$text\" 已被清理。");
    }

    return $sanitized_text;

}

sub find_illust_id {

    my ( $lrr_info ) = @_;

    my $oneshot_param = $lrr_info -> {"oneshot_param"};
    my $archive_title = $lrr_info -> {"archive_title"};
    my $logger = get_plugin_logger();

    if (defined $oneshot_param) {
        # 情况 1: "$illust_id" 即数字字符串。
        if ($oneshot_param =~ /^\d+$/) {
            return $oneshot_param;
        }
        # 情况 2: 基于 URL 的嵌入
        if ($oneshot_param =~ m{.*pixiv\.net/.*artworks/(\d+)}) {
            return $1;
        }
    }

    if (defined $archive_title) {
        # 情况 3: 归档标题提取（强模式匹配）
        # 如果使用多个元数据插件，并且归档标题需要专门调用 pixiv 插件，则使用强模式匹配。
        if ($archive_title =~ /pixiv_\{(\d*)\}.*$/) {
            return $1;
        }

        # 情况 4: 归档标题提取（弱模式匹配）
        if ($archive_title =~ /^\{(\d*)\}.*$/) {
            return $1;
        }
    }

    return "";

}

sub get_illustration_dto_from_json {
    # 从 json 对象中获取相关数据对象
    my ( $json, $illust_id ) = @_;
    return %{$json -> {'illust'} -> { $illust_id }};
}

sub get_manga_data_from_dto {
    # 获取基于漫画的数据并返回为数组。
    my ( $dto ) = @_;
    my @manga_data;

    if ( exists $dto -> {"seriesNavData"} && defined $dto -> {"seriesNavData"} ) {
        my %series_nav_data = %{ $dto -> {"seriesNavData"} };

        my $series_id = $series_nav_data{"seriesId"};
        my $series_title = $series_nav_data{"title"};
        my $series_order = $series_nav_data{"order"};

        if ( defined $series_id && defined $series_title && defined $series_order ) {
            $series_title = sanitize($series_title);
            push @manga_data, (
                "pixiv_series_id:$series_id",
                "pixiv_series_title:$series_title",
                "pixiv_series_order:$series_order",
            )
        }
    }

    return @manga_data;
}

sub get_pixiv_tags_from_dto {

    my ( $dto, $tag_languages_str ) = @_;
    my @tags;

    # 提取标签语言。
    my @tag_languages;
    if ( $tag_languages_str eq "" ) {
        push @tag_languages, "jp";
    } else {
        @tag_languages = split(/,/, $tag_languages_str);
        for (@tag_languages) {
            s/^\s+//;
            s/\s+$//;
        }
    }

    foreach my $item ( @{$dto -> {"tags"} -> {"tags"}} ) {
            
        # 遍历标签语言。
        foreach my $tag_language ( @tag_languages ) {

            if ($tag_language eq 'jp') {
                # 添加原始/jp 标签。
                my $orig_tag = $item -> {"tag"};
                if (defined $orig_tag) {
                    $orig_tag = sanitize($orig_tag);
                    push @tags, $orig_tag;
                }

            } 
            else {
                # 添加翻译标签。
                my $translated_tag = $item -> {"translation"} -> { $tag_language };
                if (defined $translated_tag) {
                    $translated_tag = sanitize($translated_tag);
                    push @tags, $translated_tag;
                }
            }
        }
    }

    return @tags;
}

sub get_user_id_from_dto {
    my ( $dto ) = @_;
    my @tags;
    my $user_id = $dto -> {"userId"};

    if ( defined $user_id ) {
        push @tags, "pixiv_user_id:$user_id";
    }

    return @tags;
}

sub get_artist_from_dto {
    my ( $dto ) = @_;
    my @tags;
    my $user_name = $dto -> {"userName"};

    if ( defined $user_name ) {
        $user_name = sanitize($user_name);
        push @tags, "artist:$user_name";
    }

    return @tags;
}

sub get_create_date_from_dto {
    my ( $dto ) = @_;
    my @tags;

    my $formattedDate = $dto -> {"createDate"};
    my $epoch_seconds = _convert_epoch_seconds($formattedDate);
    if ( defined $epoch_seconds ) {
        push @tags, "date_created:$epoch_seconds";
    }
    return @tags;
}

sub get_upload_date_from_dto {
    my ( $dto ) = @_;
    my @tags;

    my $formattedDate = $dto -> {"uploadDate"};
    my $epoch_seconds = _convert_epoch_seconds($formattedDate);
    if ( defined $epoch_seconds ) {
        push @tags, "date_uploaded:$epoch_seconds";
    }
    return @tags;
}

sub get_hash_metadata_from_json {

    my ( $json, $illust_id, $tag_languages_str ) = @_;
    my $logger = get_plugin_logger();
    my %hashdata;

    # 获取插图元数据。
    my %illust_dto = get_illustration_dto_from_json($json, $illust_id);
    my @lrr_tags;

    my @manga_data = get_manga_data_from_dto( \%illust_dto );
    my @pixiv_tags = get_pixiv_tags_from_dto( \%illust_dto, $tag_languages_str );
    push (@lrr_tags, @manga_data);
    push (@lrr_tags, @pixiv_tags);

    # 添加来源
    my $source = "https://pixiv.net/artworks/$illust_id";
    push @lrr_tags, "source:$source";

    # 添加一般元数据。
    my @user_id_data = get_user_id_from_dto( \%illust_dto );
    my @user_name_data = get_artist_from_dto( \%illust_dto );
    push (@lrr_tags, @user_id_data);
    push (@lrr_tags, @user_name_data);

    # 添加基于时间的元数据。
    my @create_date_epoch_data = get_create_date_from_dto( \%illust_dto );
    my @upload_date_epoch_data = get_upload_date_from_dto( \%illust_dto );
    push (@lrr_tags, @create_date_epoch_data);
    push (@lrr_tags, @upload_date_epoch_data);

    $hashdata{tags} = join( ', ', @lrr_tags );

    # 更改标题。
    my $illust_title = $illust_dto{"illustTitle"};
    if (defined $illust_title) {
        $illust_title = sanitize($illust_title);
        $hashdata{title} = $illust_title;
    } else {
        $logger -> error("从 json 文件中提取插图标题失败: " . Dumper($json));
    }

    return %hashdata;

}

sub get_json_from_html {

    my ( $html ) = @_;
    my $logger = get_plugin_logger();

    # 获取 'content' 内容体。
    my $dom = Mojo::DOM -> new($html);
    my $jsonstring = $dom -> at('meta#meta-preload-data') -> attr('content');
    
    $logger -> debug("初步 JSON: $jsonstring");
    my $json = decode_json $jsonstring;
    return $json;

}

sub get_html_from_illust_id {

    my ( $illust_id, $ua ) = @_;
    my $logger = get_plugin_logger();

    # 插图 ID 到 URL。
    my $URL = "https://www.pixiv.net/en/artworks/$illust_id/";

    while (1) {

        my $res = $ua -> get (
            $URL => {
                Referer => "https://www.pixiv.net"
            }
        ) -> result;
        my $code = $res -> code;
        $logger -> debug("收到代码 $code。");

        # 处理 3xx。
        if ( $code == 301 ) {
            $URL = $res -> headers -> location;
            $logger -> debug("重定向到 $URL");
            next;
        }
        if ( $code == 302 ) {
            my $location = $res -> headers -> location;
            $URL = "pixiv.net$location";
            $logger -> debug("重定向到 $URL");
            next;
        }

        # 处理 4xx。
        if ( $res -> is_error ) {
            my $code = $res -> code;
            return "error ($code) ";
        }

        # 处理 2xx。
        return $res -> body;

    }

}

sub get_metadata_from_illust_id {
    my ( $illust_id, $ua, $tag_languages_str ) = @_;
    my $logger = get_plugin_logger();

    # 初始化哈希。
    my %hashdata = ( tags => "" );

    my $html = get_html_from_illust_id( $illust_id, $ua );

    if ( $html =~ /^error/ ) {
        return ( error => "从 Pixiv 插图获取 HTML 时出错: $html");
    }

    my $json = get_json_from_html( $html );
    if ($json) {
        %hashdata = get_hash_metadata_from_json( $json, $illust_id, $tag_languages_str );
    }

    return %hashdata;

}

1;
