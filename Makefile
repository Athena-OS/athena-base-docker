BUILDDIR=$(shell pwd)/build
OUTPUTDIR=$(shell pwd)/output

define rootfs
	mkdir -vp $(BUILDDIR)/alpm-hooks/usr/share/libalpm/hooks
	find /usr/share/libalpm/hooks -exec ln -sf /dev/null $(BUILDDIR)/alpm-hooks{} \;

	mkdir -vp $(BUILDDIR)/var/lib/pacman/ $(OUTPUTDIR)
	install -Dm644 /usr/share/devtools/pacman.conf.d/multilib.conf $(BUILDDIR)/etc/pacman.conf
	sed -i "s/NoProgressBar/#NoProgressBar/g" $(BUILDDIR)/etc/pacman.conf
	cat pacman-conf.d-noextract.conf >> $(BUILDDIR)/etc/pacman.conf

	fakechroot -- fakeroot -- pacman -Syyu -r $(BUILDDIR) \
		--noconfirm --dbpath $(BUILDDIR)/var/lib/pacman \
		--config $(BUILDDIR)/etc/pacman.conf \
		--noscriptlet \
		--hookdir $(BUILDDIR)/alpm-hooks/usr/share/libalpm/hooks/ $(2) $(3) $(4) $(5) $(6) $(7) $(8) $(9) $(10) $(11)

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
    sed -i -e "s/#Server/Server/g" "$(BUILDDIR)/etc/pacman.d/mirrorlist"

    # remove problematic mirror servers
    sed -i -e "/geo.mirror.pkgbuild.com/d" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
	sed -i -e "/mirrors.eze.sysarmy.com/d" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
    sed -i -e "/mirror.osbeck.com/d" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
    sed -i -e "/mirror.theo546.fr/d" "$(BUILDDIR)/etc/pacman.d/mirrorlist"
    sed -i -e "/cdn-mirror.chaotic.cx/d" "$(BUILDDIR)/etc/pacman.d/chaotic-mirrorlist"


    # fakeroot to map the gid/uid of the builder process to root

    fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(BUILDDIR) -c . -f $(OUTPUTDIR)/$(1).tar
    
	# keep XZ as extension. If you use ZST instead of XZ, GitHub Actions workflow is not able to build and push correctly the image

    cd $(OUTPUTDIR); xz -9 -T0 -f $(1).tar; sha256sum $(1).tar.xz > $(1).tar.xz.SHA256
endef

define dockerfile
	sed -e "s|TEMPLATE_ROOTFS_FILE|$(1).tar.xz|" \
	    Dockerfile.template > $(OUTPUTDIR)/Dockerfile.$(1)
endef

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)

$(OUTPUTDIR)/base.tar.xz:
	$(call rootfs,base,base,archlinux-keyring,pacman-mirrorlist,athena-keyring,athena-mirrorlist,chaotic-keyring,chaotic-mirrorlist,rate-mirrors)

$(OUTPUTDIR)/base-devel.tar.xz:
	$(call rootfs,base-devel,base base-devel,archlinux-keyring,pacman-mirrorlist,athena-keyring,athena-mirrorlist,chaotic-keyring,chaotic-mirrorlist,rate-mirrors)

$(OUTPUTDIR)/Dockerfile.base: $(OUTPUTDIR)/base.tar.xz
	$(call dockerfile,base)

$(OUTPUTDIR)/Dockerfile.base-devel: $(OUTPUTDIR)/base-devel.tar.xz
	$(call dockerfile,base-devel)

.PHONY: docker-base
athena-base: $(OUTPUTDIR)/Dockerfile.base
	docker buildx build -f $(OUTPUTDIR)/Dockerfile.base -t athenaos/base:latest $(OUTPUTDIR)

.PHONY: docker-base-devel
athena-base-devel: $(OUTPUTDIR)/Dockerfile.base-devel
	docker buildx build -f $(OUTPUTDIR)/Dockerfile.base-devel -t athenaos/base-devel:latest $(OUTPUTDIR)
