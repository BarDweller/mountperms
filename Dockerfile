FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Install tools to add/remove users/groups.
RUN microdnf install --setopt=install_weak_deps=0 --setopt=tsflags=nodocs shadow-utils && \
  microdnf clean all

# Add 1000/1000
RUN groupadd groupa --gid 1000 && \
  useradd --uid 1000 --gid 1000 -m -s /bin/bash usera
# Add 2000/2000
RUN groupadd groupb --gid 2000 && \
  useradd --uid 2000 --gid 2000 -m -s /bin/bash userb

RUN mkdir /ownedbya && chown usera:groupa /ownedbya && chmod 755 /ownedbya
RUN mkdir /restrictedtoa && chown usera:groupa /restrictedtoa && chmod 700 /restrictedtoa
RUN mkdir /ownedbyb && chown userb:groupb /ownedbyb && chmod 755 /ownedbyb
RUN mkdir /restrictedtob && chown userb:groupb /restrictedtob && chmod 700 /restrictedtob

RUN mkdir /alsoownedbya && chown usera:groupa /alsoownedbya && chmod 755 /alsoownedbya

#ensure these paths do not exist
RUN rm -f /doesnotexist
RUN rm -f /alsonotexist
