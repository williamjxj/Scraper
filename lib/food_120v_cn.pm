package food_120v_cn;

use config;
use common;
@ISA = qw(common);
use strict;
our ( $dbh, $sth );

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
		<div\sclass="n_txt2"
		(.*)
		</ul>
		(?:.*?)
		<div\sclass="pagination">
	}sgix
	  )
	{
		return $1;
	}
	return '';
}
# extract 整个网页，提取出来关于页面翻转的有效部分。
sub parse_list_page_2 {
	my ( $self, $html ) = @_;
	while (
		$html =~ m {
		<div\sclass="page-bottom">
		(.*)
		</div>
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

# 这里取出下一页的有效地址.
sub get_next_page {
	my ( $self, $html ) = @_;
	return '' unless $html;
	while (
		$html =~ m {
		<span\sclass="current"
		(?:.*?)
		<a\s(?:.*?)href="(.*?)"
		(?:.*?)
		</a>
	}sgix
	  )
	{
		return $1;
	}
	return '';
}

# 解析文章网页，提取处标题，出处，日期，内容，插入数据库的contexts表。
sub parse_detail {
	my ( $self, $html ) = @_;
	my @ary = ();

	while (
		$html =~ m{
		<div\sclass="news_nav"
		(?:.*?)
		<span>
		(?:.*?)
		<a(?:.*?)>
		(.*?)		#分类item
		</a>  
		(?:.*?)
		<div\sclass="title">
		(.*?)		#标题name
		</div>
		(?:.*?)
		<div\sclass="time">
		(.*?) 	#日期
		</div>
		(?:.*?)
		<div\sclass="Source">
		(.*?)	#来源
		</div>
		(?:.*?)
		<div\sclass="news_wb"	>
		(.*?)	#正文
		<div\sclass="news_xx1"
	}sgix
	  )
	{
		my ( $item_name, $name, $date, $resource, $content ) = ( $1, $2, $3, $4, $5 );
		$date =~ s/\D+//g; #20120824

		$content =~ s/(<\/div>)+$/''/ if( $content =~ m/<\/div>$/ );

		push( @ary, $name, $item_name, $resource, $date, $content );
	}
	return @ary;
}

sub parse_keywords_list {
	my ( $self, $html ) = @_;
	while (
		$html =~ m {
			<div\sclass="news_xx1"
			(.*?)
			</div>
	}sgix
	)
	{
		return $1;
	}
	return '';
}
#解析并保存关键词。
sub get_keywords {
	my ( $self, $html ) = @_;
	my $aoh = [];

	while (
		$html =~ m{
			<a(?:.*?)>
			(.*?)
			</a>
	}sgix
	  )
	{
		push( @{$aoh}, $1 );
	}
	return $aoh;
}

sub select_category {
	my ( $self ) = @_;
	my @row = ();
	$sth = $self->{dbh}->prepare( q{ select cid from categories where name=? } );
	$sth->execute(FOOD);
	@row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}
# 总循环的第一步。
sub select_items {
	my ( $self ) = @_;
	my $aref = [];
	$sth = $self->{dbh}->prepare( q{ select iid, name, iurl from items where category=? and groups=1 order by weight } );
	$sth->execute(FOOD);
	$aref = $sth->fetchall_arrayref();
	$sth->finish();
	return $aref;
}
# 好像没有用到。
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

sub select_keywords {
	my ( $self, $k ) = @_;
	my $sql =
	    "select * from contents where content like '%" . $k . "%'";
	$self->show_results($sql);
}

#补丁: 最后执行,将content.iid=NULL 改为items.iid. 回头改正:
sub update_contents  {
	my ($self) = @_;
	my $sql = "update contents c, (select iid,name from items) i set c.iid=i.iid where c.iid is NULL and c.item=i.name";
	$sth->execute();	
}

1;
