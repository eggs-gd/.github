# SonarQube pull request icons

The icons the SonarQube community branch plugin puts in its pull request comments
(the quality gate badges, the issue counters, the coverage and duplication charts, the
ratings, the severities). They are copied unchanged from
[mc1arke/sonarqube-community-branch-plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin),
`src/main/resources/static`, which is licensed under the LGPL-3.0; only the PNG files are kept.

Why they are here: the maintainer's SonarQube server is on a LAN, so GitHub cannot load the
icons from it and the comments show broken images. The setting **Administration → Configuration →
General → Pull Request → Images base URL** is

```
https://raw.githubusercontent.com/eggs-gd/.github/main/sonarqube/images
```

After a plugin update that changes the icons, copy the PNG files again from the same path.
