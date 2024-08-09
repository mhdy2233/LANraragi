package LANraragi::Plugin::Metadata::CopyTags;

use utf8;
use strict;
use warnings;

use LANraragi::Model::Plugins;
use LANraragi::Utils::Logging qw(get_logger);

# 关于插件的元信息。
sub plugin_info {

    return (
        # 标准元数据
        name        => "标签复制器",  # 插件名称
        type        => "metadata",   # 插件类型：元数据
        namespace   => "copytags",    # 命名空间
        author      => "Difegue",     # 作者
        version     => "2.1",         # 版本号
        description => "将指定的标签添加到你的元数据中。适合批量操作！",  # 插件描述
        icon        => "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA\nB3RJTUUH4wYCFQ05iQtpeQAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUH\nAAAD8ElEQVQ4y4WUW2yURRTHfzPfty2UWrZbqdrdhktowQAJiQ/iDUwkaFJ5IAQfGjWBByMhwYAm\nBH3xqT5ArARS9cUgJC1qjCDxCY1JEy6lLVJrW9lKq6Wlgcqy2W7b/S4zx4fdbstFneRMZjLJb/7n\nf86MOn78+MlEIvE6gIhgRRARECGTmaS0tJT6+vrvo7HKxserq6f4v9Hc3PyxiBh5yBgYGJBUKiW/\n9vZKV/eVb7s6OyN79uxhbGwMKVx8f2gRUUEQEAQhfhDg+wGeHxAaA8DZs2e50tVNZ+flJ3v7B8ra\n29uJx+M0NTXhed6DCg8dPtzs+77xfV883xfP8yVXCM/zxA9CCcNQzv3402+bX96yuK2tjd27dxOP\nx2loaCCdTj+gkIJlICAFLz0vx/RMjmx2kunpaXK5nF5au3RJb29fzdq162ouX+p4ZHh4mO3bt98j\n0DU2n5oUZqUUvudz8cIFEvEEoQkRIBarXLFr584frLVmdHRUj4yNXu3r69tbVVV1u7W1lcbGxjxQ\njMzjKxAw1rJoURlr1q7B9wMEQaFKBerDwMfzPKKLo6t+uXp12Z07d16pq6tL79ixg0gkgjamkCv5\nvItKUfkrFCilmN0orZmayrJgQSlDQ0NPHz3WskhrTXd3NwBaxBR8m007v7aza+a8RQTXcaipTTAx\nMYHn+2SnJ4nFYgwODuaBRmxB3FylEEGsLRKliBZcHSFVkSFVOUWiOk5uxiObzZJKpfJAa8wciPvA\nzIflzxSKW+EtDgx8wKUbXVSYcuM4TtEWba1VSkGkJILruvmIuFibh2gNjtI4SuNqB6XBVQ7jFTdo\nK/+GiWemNmmt59omFouNfXf6dLsIalZZGJrI6lV1zwIcOP8hQ871YsE0mpRJUVFWTnZ5WjpSF09t\n+WhbJdf4DMDdv2/foYMHDx46c+YMW7dupba2lutDw1UrV674G+B3/xr9VT1gVLFMWjk4SoOg/ope\nZyo9/elzq1/QQIs7v8u11oyMjFBTU6OszKas0I4D6t4nG1qDAqwWJnWG0IbrAdz737ZSCmsNUvAw\nmAnxJsxcHyEoV+FUgDiWhXfL2RS89FXdtSfeYss8oDEGz/Ow1mKMQReq9vXmE4SSVyPAAl3KiT9b\n2X/7XZZMPcbz9sWTl94/9+bn63vUXvaKCxCGIclkkmQyCcCxlhZJ/jHI3XR60hqjpdinloiUSJ/0\nlZQuLC/Z0L9B4n2V73zR08ORXUcEyFd2fHycTCZT7KWLHR3q5s3xyslMxlhrlYjklVvLuv6V/tE3\nTr29vGzZxlffe+q1jV82hObRwFZXVxONRvnXn/e/ounCJzU/z5yPPOzsH4cGnEj6mhLzAAAAAElF\nTkSuQmCC",
        parameters => [ { type => "string", desc => "要复制的标签，逗号分隔。" } ]
    );

}

# 插件必须实现的函数
sub get_tags {

    shift;
    my $lrr_info = shift;        # 全局信息哈希
    my ($tagstocopy) = @_;       # 插件参数

    my $logger = get_logger( "标签复制", "插件" );

    # 标签复制是第一个全局参数
    $logger->debug( "发送到 LRR 的标签： " . $tagstocopy );
    return ( tags => $tagstocopy );

}

1;
