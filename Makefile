BUILDDIR=$(shell pwd)/build
OUTPUTDIR=$(shell pwd)/output

define rootfs
	mkdir -vp $(BUILDDIR)/alpm-hooks/usr/share/libalpm/hooks
	find /usr/share/libalpm/hooks -exec ln -sf /dev/null $(BUILDDIR)/alpm-hooks{} \;

	mkdir -vp $(BUILDDIR)/var/lib/pacman/ $(OUTPUTDIR)
	install -Dm644 /usr/share/devtools/pacman.conf.d/extra.conf $(BUILDDIR)/etc/pacman.conf
	cat pacman-conf.d-noextract.conf >> $(BUILDDIR)/etc/pacman.conf

	fakechroot -- fakeroot -- pacman -Sy -r $(BUILDDIR) \
		--noconfirm --dbpath $(BUILDDIR)/var/lib/pacman \
		--config $(BUILDDIR)/etc/pacman.conf \
		--noscriptlet \
		--hookdir $(BUILDDIR)/alpm-hooks/usr/share/libalpm/hooks/ $(2) $(3) $(4) $(5) $(6) $(7) $(8) $(9)

	cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* $(BUILDDIR)/

	fakechroot -- fakeroot -- chroot $(BUILDDIR) update-ca-trust
	fakechroot -- fakeroot -- chroot $(BUILDDIR) locale-gen
	fakechroot -- fakeroot -- chroot $(BUILDDIR) sh -c 'pacman-key --init && pacman-key --populate && bash -c "rm -rf etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pubring.gpg~,gnupg.S.}*"'

	ln -fs /etc/os-release $(BUILDDIR)/usr/lib/os-release

	# add system users
	fakechroot -- fakeroot -- chroot $(BUILDDIR) /usr/bin/systemd-sysusers --root "/"

	# remove passwordless login for root (see CVE-2019-5021 for reference)
	sed -i -e 's/^root::/root:!:/' "$(BUILDDIR)/etc/shadow"

        # uncomment all mirrorlist servers
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "s/#Server/Server/g" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "s/#Server/Server/g" "$(BUILDDIR)/etc/pacman.d/blackarch-mirrorlist"

        # remove problematic mirror servers
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "/geo.mirror.pkgbuild.com/d" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "/mirror.osbeck.com/d" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "/mirrors.fosshost.org/d" "$(BUILDDIR)/etc/pacman.d/blackarch-mirrorlist"
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "/mirrors.fossho.st/d" "$(BUILDDIR)/etc/pacman.d/blackarch-mirrorlist"
        fakechroot -- fakeroot -- chroot $(BUILDDIR) sed -i -e "/cdn-mirror.chaotic.cx/d" "$(BUILDDIR)/etc/pacman.d/chaotic-mirrorlist"


	# fakeroot to map the gid/uid of the builder process to root

	fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(BUILDDIR) -c . -f $(OUTPUTDIR)/$(1).tar

	cd $(OUTPUTDIR); zstd --long -T0 -8 $(1).tar; sha256sum $(1).tar.zst > $(1).tar.zst.SHA256
endef

define dockerfile
	sed -e "s|TEMPLATE_ROOTFS_FILE|$(1).tar.zst|" \
	    Dockerfile.template > $(OUTPUTDIR)/Dockerfile.$(1)
endef

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)

$(OUTPUTDIR)/base.tar.zst:
	$(call rootfs,base,base,pacman-mirrorlist,archlinux-keyring,athena-keyring,blackarch-keyring,blackarch-mirrorlist,chaotic-keyring,chaotic-mirrorlist)

$(OUTPUTDIR)/base-devel.tar.zst:
	$(call rootfs,base-devel,base base-devel,pacman-mirrorlist,archlinux-keyring,athena-keyring,blackarch-keyring,blackarch-mirrorlist,chaotic-keyring,chaotic-mirrorlist)

$(OUTPUTDIR)/Dockerfile.base: $(OUTPUTDIR)/base.tar.zst
	$(call dockerfile,base)

$(OUTPUTDIR)/Dockerfile.base-devel: $(OUTPUTDIR)/base-devel.tar.zst
	$(call dockerfile,base-devel)

.PHONY: docker-image-base
image-base: $(OUTPUTDIR)/Dockerfile.base
	docker build -f $(OUTPUTDIR)/Dockerfile.base -t athenaos/base:latest $(OUTPUTDIR)

.PHONY: docker-image-base-devel
image-base-devel: $(OUTPUTDIR)/Dockerfile.base-devel
	docker build -f $(OUTPUTDIR)/Dockerfile.base-devel -t athenaos/base-devel:latest $(OUTPUTDIR)
  
