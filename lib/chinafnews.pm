package chinafnews;

use config;
use common;
@ISA = qw(common);
use strict;
our ( $sth );

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'dixi';
	bless $self, $type;
}

# 从各个category的首页开始抓取.
# extract 整个网页，提取出来有效部分。
sub parse_list_page_1 {
	my ( $self, $html ) = @_;
	while (
		$html =~ m {
		<div\sclass="fs-14\scor-06c\spadd-20"
		(.*)
		</ul>
		(?:.*?)
		<ul\sclass="inline">
	}sgix
	  )
	{
		return $1;
	}
	return '';
}
# 这里取出所有文章链接的有效地址.
sub get_links {
	my ( $self, $html ) = @_;
	my $aoh = [];
	while (
		$html =~ m {
		<li>
		(?:.*?)
		<a\s(?:.*?)href="(.*?)"
		(?:.*?)
		</li>
	}sgix
	  )
	{
		push( @{$aoh}, $1 );
	}
	return $aoh;
}
# extract 整个网页，提取出来关于页面翻转的有效部分。
sub parse_list_page_2 {
	my ( $self, $html ) = @_;
	while (
		$html =~ m {
		<ul\sclass="inline">
		(.*)
		</ul>
		(?:.*?)
		<div\sclass="clear"
	}sgix
	  )
	{
		return $1;
	}
	return '';
}
# 这里取出下一页的有效地址.
sub get_next_page {
	my ( $self, $html ) = @_;
	return '' unless $html;
	while (
		$html =~ m {
		<li>
		(?:.*?)
		<a\s(?:.*?)class="now"
		(?:.*?)
		<a\s(?:.*?)href="(.*?)"
		(?:.*?)
		</li>
	}sgix
	  )
	{
		return $1;
	}
	return '';
}

# 解析文章网页，提取处标题，出处，日期，内容，插入数据库的contents表。
sub parse_detail {
	my ( $self, $html ) = @_;
	my @ary = ();

	while (
		$html =~ m{
		<div\sid=contentA
		(?:.*?)
		<h1>(.*?)</h1>	 #标题: title
		(?:.*?)
		<span\sid=media_span>
		(.*?)		#来源: from
		</span>
		(?:.*?)
		<div\sclass=r>
		(.*?) 	#日期: date
		</div>
		(?:.*?)
		<div\sid=contentText(?:.*?)>
		(.*?)	#正文: content
		<div\sclass="function\sclear"
	}sgix) {
		my ( $name, $resource, $date, $content ) = ( $1, $2, $3, $4 );
		push( @ary, $name, $resource, $date, $content );
	}
	return @ary;
}
sub parse_detail_without_from {
	my ( $self, $html ) = @_;
	my @ary = ();
	while (
		$html =~ m{
		<div\sid=contentA
		(?:.*?)
		<h1>(.*?)</h1>	 #标题: title
		(?:.*?)
		<div\sclass=r>
		(.*?) 	#日期: date
		</div>
		(?:.*?)
		<div\sid=contentText(?:.*?)>
		(.*?)	#正文: content
		<div\sclass="function\sclear"
	}sgix) {
		my ( $name, $date, $content ) = ( $1, $2, $3);
		push( @ary, $name, $date, $content );
	}
	return @ary;
}

sub patch_date {
	my ($self, $date) = @_;
	$date =~ s/^\s+// if ( $date =~ m/^\s/ );
	$date =~ s/\s+$// if ( $date =~ m/\s$/ );
	$date =~ s/,\s+/ /;
	$date =~ s/ \w+$//;
	return $date;
}

sub patch_content {
	my ($self, $content) = @_;
	$content =~ s/<table\sid="pagination".*$//sg if ($content =~ m/id="pagination"/);
	#$content =~ s/<\/div>$//sg if( $content =~ m/<\/div>$/ );
	return $content;
}

# 好像没有用到。
sub select_category {
	my ( $self ) = @_;
	my @row = ();
	$sth = $self->{dbh}->prepare( q{ select cid from categories where name=? } );
	$sth->execute(FOOD);
	@row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

sub select_items {
	my ( $self ) = @_;
	my $aref = [];
	$sth = $self->{dbh}->prepare( q{ select iid, name, iurl from items where category=? and groups=2 order by weight } );
	$sth->execute(FOOD);
	$aref = $sth->fetchall_arrayref();
	$sth->finish();
	return $aref;
}
# 总循环的第一步。
# Only for chinafnews: cid=3 and groups=2
sub select_items_by_cid {
	my ( $self, $cid ) = @_;
	my $aref = [];
	$sth = $self->{dbh}->prepare( q{ select iid, name, iurl from items where cid=? and groups=2 order by iid } );
	$sth->execute($cid);
	$aref = $sth->fetchall_arrayref();
	$sth->finish();
	return $aref;
}
sub select_item_by_id {
	my ( $self, $iid ) = @_;
	my @row = ();
	$sth = $self->{dbh}->prepare( q{ select iid, name, iurl from items where iid=? } );
	$sth->execute($iid);
	@row = $sth->fetchrow_array();
	$sth->finish();
	return \@row;
}

sub select_item_by_name {
	my ( $self, $name ) = @_;
	my @row = ();
	$sth = $self->{dbh}->prepare( q{ select iid from items where name=? } );
	$sth->execute($name);
	@row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

# 好像没有用到。
sub select_channel_by_id {
	my ( $self, $mid ) = @_;
	my $sql = qq{ select mid, url, name from channels where mid=$mid };
	my @row = ();
	$sth = $self->{dbh}->prepare( $sql );
	$sth->execute();
	@row = $sth->fetchrow_array();
	$sth->finish();
	return \@row;
}

sub select_keywords {
	my ( $self, $k ) = @_;
	my $sql = "select * from contents where content like '%" . $k . "%'";
	$self->show_results($sql);
}

sub insert_contents
{
	my ($self, $h) = @_;
	$h->{'clicks'} = $self->generate_random();
	$h->{'likes'} = $self->generate_random(100);
	$h->{'guanzhu'} = $self->generate_random(100);
		
	my $sql = qq{ insert ignore into contents
		(title,
		url,
		pubdate,
		author, 
		source,
		category,
		cate_id,
		item,
		iid,
		clicks,
		likes,
		guanzhu,
		createdby,
		created,
		content
	) values(
		$h->{'title'}, 
		$h->{'url'},
		$h->{'pubdate'},
		$h->{'author'},
		$h->{'source'},
		$h->{'category'},
		$h->{'cate_id'},
		$h->{'item'},
		$h->{'item_id'},
		$h->{'clicks'},
		$h->{'likes'},
		$h->{'guanzhu'},
		$h->{'createdby'},
		now(),
		$h->{'content'}
	)};
	$self->{dbh}->do($sql);
}

# 有用的参考：
sub strip_dixi_userbody {
	my ( $self, $html ) = @_;
	$html =~ s/<!-- CLTAG GeographicArea=NW -->.*$//si
	  if ( $html =~ m/CLTAG GeographicArea/i );
	return $html;
}

# Thu 25 Mar
sub get_end_date {
	my ( $self, $todate ) = @_;
	my $sth =
	  $self->{dbh}->prepare( qq{ select date_format(date_sub(now(), interval } 
		  . $todate
		  . qq{ day), '%a %b %d' ) } );
	$sth->execute();
	my @row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

1;
