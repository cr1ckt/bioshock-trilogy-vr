// The GitHub "owner/repo" whose releases the launcher checks, links to and downloads
// from. Set at configure time with -DBVR_RELEASES_REPO=owner/repo so a fork's build
// updates from the fork's own releases; the default is the project's home.
#pragma once
#ifndef BVR_RELEASES_REPO
#define BVR_RELEASES_REPO "VR-Stereo-Hub/bioshock-trilogy-vr"
#endif
