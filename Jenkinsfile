#!groovy

/* Copyright (c) Citrix Systems, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms,
 * with or without modification, are permitted provided
 * that the following conditions are met:
 *
 * *   Redistributions of source code must retain the above
 *     copyright notice, this list of conditions and the
 *     following disclaimer.
 * *   Redistributions in binary form must reproduce the above
 *     copyright notice, this list of conditions and the
 *     following disclaimer in the documentation and/or other
 *     materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

node('xencenter') {

  try {

    properties([
      [
        $class  : 'BuildDiscarderProperty',
        strategy: [$class: 'LogRotator', numToKeepStr: '10', artifactNumToKeepStr: '10']
      ]
    ])

    stage('Clean workspace') {
      deleteDir()
    }

    stage('Checkout source') {
      checkout([
        $class           : 'GitSCM',
        branches         : scm.branches,
        extensions       : [
          [$class: 'RelativeTargetDirectory', relativeTargetDir: 'dotnet-packages.git'],
          [$class: 'LocalBranch', localBranch: '**'],
          [$class: 'CleanCheckout']
        ],
        userRemoteConfigs: scm.userRemoteConfigs
      ])
    }

    def GIT_COMMIT = bat(
      returnStdout: true,
      script: """
      @echo off
      cd ${env.WORKSPACE}\\dotnet-packages.git
      git rev-parse HEAD
      """
    ).trim()

    def GIT_BRANCH = bat(
      returnStdout: true,
      script: """
      @echo off
      cd ${env.WORKSPACE}\\dotnet-packages.git
      git rev-parse --abbrev-ref HEAD
      """
    ).trim()

    stage('Build') {
      dir("${env.WORKSPACE}\\dotnet-packages.git"){
        powershell """.\\build.ps1 -SnkKey ${env.SNK_LOCATION}"""
      }
    }

    stage('Upload') {
      // note that the pattern further down is relative to this dir
      dir("${env.WORKSPACE}\\dotnet-packages.git\\_build\\output") {

        def server = Artifactory.server('repo')
        def buildInfo = Artifactory.newBuildInfo()
        buildInfo.env.filter.addInclude("*")
        buildInfo.env.collect()

        GString artifactMeta = "build.name=${env.JOB_NAME};build.number=${env.BUILD_NUMBER};vcs.url=${env.CHANGE_URL};vcs.branch=${GIT_BRANCH};vcs.revision=${GIT_COMMIT}"

        // IMPORTANT: do not forget the slash at the end of the target path
        GString uploadSpec = """
        {
          "files": [
            {
              "pattern": "*",
              "flat": "false",
              "target": "xc-local-build/dotnet-packages/${GIT_BRANCH}/${env.BUILD_NUMBER}/",
              "props": "${artifactMeta}"
            }
          ]
        }
      """

        def buildInfo_upload = server.upload(uploadSpec)
        buildInfo.append buildInfo_upload
        server.publishBuildInfo buildInfo
      }
    }

    currentBuild.result = 'SUCCESS'

  } catch (Exception ex) {
    currentBuild.result = 'FAILURE'
    throw ex as java.lang.Throwable
  } finally {
    step([
      $class                  : 'Mailer',
      notifyEveryUnstableBuild: true,
      recipients              : "${env.XENCENTER_DEVELOPERS}",
      sendToIndividuals       : true])
  }
}
