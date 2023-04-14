# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'KifuCam' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'OpenCV'

  #pod 'AWSAutoScaling'
  #pod 'AWSCloudWatch'
  pod 'AWSCognito'
  pod 'AWSCognitoIdentityProvider'
  #pod 'AWSDynamoDB'
  #pod 'AWSEC2'
  #pod 'AWSElasticLoadBalancing'
  #pod 'AWSIoT'
  #pod 'AWSKinesis'
  #pod 'AWSLambda'
  #pod 'AWSMachineLearning'
  #pod 'AWSMobileAnalytics'
  pod 'AWSS3'
  #pod 'AWSSES'
  #pod 'AWSSimpleDB'
  #pod 'AWSSNS'
  #pod 'AWSSQS'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end 
  end 
end



