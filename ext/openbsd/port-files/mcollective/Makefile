PKG_ARCH=	*
COMMENT=	The Marionette Collective	

DISTNAME=	mcollective-2.2.1

CATEGORIES=	sysutils

HOMEPAGE=	http://puppetlabs.com/mcollective/
MASTER_SITES=	http://puppetlabs.com/downloads/mcollective/
EXTRACT_SUFX=	.tgz

# GFDL
PERMIT_PACKAGE_CDROM=	Yes
PERMIT_PACKAGE_FTP=	Yes
PERMIT_DISTFILES_CDROM=	Yes
PERMIT_DISTFILES_FTP=	Yes

NO_BUILD=	Yes
NO_REGRESS=	Yes

# makefile is in ext/
MAKE_FILE=ext/Makefile

post-patch:
	${SUBST_CMD} ${WRKSRC}/etc/server.cfg.dist
	rm -f ${WRKSRC}/etc/server.cfg.dist.{orig,beforesubst}

.include <bsd.port.mk>
