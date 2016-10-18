#!/usr/bin/env perl
use 5.014;
use warnings;
use utf8;
use autodie;
use lib 'webapp/perl/lib';

=head1 DESCRIPTION

wikipedia_all.jsonを ok/ng/yearの3つに分割する

=cut

use JSON::XS qw/decode_json/;
use Encode qw/decode_utf8/;

use Isuda::Web;
my $dbh = Isuda::Web->new->dbh;
$dbh->do('TRUNCATE entry');

my $WORK_DIR = $ENV{ISUDA_DATA_DIR} || '.tmp';

my $file = "$WORK_DIR/wikipedia_all.json";
open my $fh, '<', $file;

my $ok_file = "$WORK_DIR/wikipedia_ok.json";
my $ng_file = "$WORK_DIR/wikipedia_ng.json";
my $year_file = "$WORK_DIR/wikipedia_year.json";
eval {unlink $_ for ($ok_file, $ng_file, $year_file) };

open my $ok_fh, '>>', $ok_file;
open my $ng_fh, '>>', $ng_file;
open my $year_fh, '>>', $year_file;

sub out {
    my $line = shift;
    my $target_fh = $ng_fh;
    if (valid(decode_utf8($line))) {
        $target_fh = $ok_fh;
    }
    print $target_fh $line;
}

my %seen;
my $counter = 0;
while (my $line = <$fh>) {
    $counter++;
    unless ($counter % 10000) {
        say "done $counter";
    }
    my $data = decode_json $line;
    next if $seen{$data->{k}}++;
    if ($data->{k} =~ /^\d+年$/) {
        next unless valid($data->{v});
        next if $data->{v} =~ /^#(?:REDIRECT|転送)/msi;
        eval {$dbh->query(sql(), $data->{k}, $data->{v})};
        if (!$@) {
            print $year_fh $line;
        }
        next;
    }
    next if length($data->{k}) < 3;
    next if $data->{v} =~ /^#(?:REDIRECT|転送)/msi;
    next if $data->{k} =~ m![/:&]!;
    next if 0.08 < rand();

    eval {$dbh->query(sql(), $data->{k}, $data->{v})};
    if (!$@) {
        out($line);
    }
}

sub sql {
    'INSERT INTO entry '.
    '(author_id, keyword, description, created_at, updated_at) VALUES ' .
    '(1, ?, ?, NOW(), NOW())';
}

sub ngreg {
    qr/(?:[吃唖妾跛躄]|(?:健全なる精神は健全なる身体に宿|(?:娘を片付|股に掛)け|将棋倒しにな|群盲象をなで|本腰を入れ|灸を据え|ずらか|婿をと|嫁にや|発狂す)る|(?:[屑床魚]|汲み取り|ゴミ|バタ|代書|八百|周旋|担ぎ|蛸部)屋|イ(?:ン(?:ディアン嘘つかない|チキ)|カサマ|タ公|モ)|盲(?:[人目縞]|蛇に怖じず|判を押す|愛する|滅法)?|馬(?:[丁喰]|鹿(?:でもチョンでも|チョンカメラ))|(?:[坑漁農鉱]|(?:線路)?工|潜水|雑役)夫|(?:(?:越後の米|まえ)つ|ぽん引|釣り書)き|エ(?:(?:スキモ|ディタ)ー|チゼンクラゲ)|ジ(?:(?:プシ|ュ)ー|ャ(?:ップ|リ))|チ(?:ャ(?:リンコ|ンコロ)|ョン|ビ)|女(?:[中傑工給]|の腐ったような|子供)|ブ(?:[スツ]|ラインドタッチ|タ箱)|狂(?:[う人女]|気(?:の沙汰)?)|(?:ダッチマ|ルンペ|ザギ|ナオ)ン|(?:皮[切被]|千摺|地回|首切)り|サ(?:ラ(?:ブレッド|金)|ツ)|精(?:神(?:分裂病|異常)|薄)|(?:[外芸非鮮]|半島|紅毛)人|(?:いちゃも|あらめ|運ちゃ)ん|(?:引かれ|労務|町医|障害)者|土(?:[人工方]|左衛門|建屋)|支那(?:[人竹]|料理|蕎麦)?|未(?:開(?:発国|人)|亡人)|落(?:ちこぼれ|とし前|人部落)|(?:すけこま|ほんぼ|犬殺)し|ア(?:イヌ系|メ公|ル中|カ)|ス(?:チュワーデス|ラム|ケ)|ポ(?:ッポー屋|コペン|リ公)|三(?:韓征伐|つ口|国人|助)|片(?:[目端肺親足]|手落ち)|(?:合いの|魔女っ|連れ)子|南(?:部の鮭の鼻まがり|鮮)|が(?:っぷり四つ|ちゃ目)|ニ(?:コヨン|ガー|グロ)|パ(?:ーマ屋|クる|ン助)|ヤ(?:ンキー|バい|ー様)|不(?:可触民|治の病|具)|日(?:本のチベット|雇い)|気違い(?:に刃物|沙汰)?|特殊(?:学[校級]|部落)|か(?:さっかき|ったい)|オ(?:ールドミス|カマ)|タ(?:ケノコ医者|タキ)|(?:やさぐ|知恵遅)れ|(?:伊勢|河原)?乞食|ど(?:さ回り|ん百姓)|ゲ(?:ンナマ|ーセン)|人(?:[夫足]|非人)|低(?:脳児?|開発国)|小(?:[人僧]|使い)|(?:しらっ|うん)こ|(?:富山の三|露)助|お(?:わい屋|巡り)|トルコ(?:風呂|嬢)|台湾(?:ハゲ|政府)|拡張(?:団長?|員)|朝鮮(?:人参|征伐)|足(?:を洗う|切り)|(?:助産|看護)婦|(?:後進|第三)国|(?:痴呆|蒙古)症|保(?:線工夫|母)|出(?:戻り|稼ぎ)|藪(?:医者|睨み)|身(?:元調査|分)|(?:新平|移)民|(?:沖仲|給)仕|ク(?:ンニ|ロ)|天才と狂人は紙一重|寄(?:せ場|目)|養(?:老院|護)|黒(?:んぼ|人)|聾(?:桟敷)?|レントゲン技師|屠殺[人場]?|[文明色]盲|[表裏]日本|ペイ[中患]|処女[作峰]|四つ[足辻]|心障[児者]|掃除[夫婦]|浮浪[児者]|郵便[夫屋]|[強青]姦|[業癩]病|[産老]婆|くわえ込む|ガ[キサ]|キ[チ印]|ズージャー|上方の贅六|下[女男]|家[柄系]|情[夫婦]|玉袋筋太郎|育ちより氏|蛙の子は蛙|血[筋統]|ぎっちょ|めっかち|ドヤ街?|ロンパリ|他力本願|垂れ流す|士農工商|川向こう|植物人間|溺れ死ぬ|滑り止め|自閉症児|カッペ|コロシ|ハーフ|マンコ|令?嬢|借り腹|共稼ぎ|名門校|孤児院|尻拭い|当て馬|役不足|手ん棒|確信犯|脳膜炎|興信所|踏切番|過去帳|シマ|デカ|ノビ|ヒモ|ヨツ|丁稚|中共|二号|傴僂|北鮮|坊主|姦通|子供|愚鈍|按摩|板前|正妻|毛唐|淫売|満州|父兄|猫糞|獣医|田舎|番太|白痴|百姓|穢多|端女|職工|肌色|苦力|虚仮|親方|貧農|近目|部落|酋長|醜男|隠坊|飯場|ＯＬ)/ms
}

sub ngurl_reg {
    qr`https?://(?:[-_.!~*'(|)A-Za-z0-9%;:&=+\$,]*@)?(?:[0-9A-Za-z_-]+(?:\.[0-9A-Za-z_-]+)*(?:\.(?:xxx|sex|porn|adult))\.?)`msi;
}

sub valid {
    my $w = shift;
    $w !~ ngreg() && $w !~ ngurl_reg();
}
