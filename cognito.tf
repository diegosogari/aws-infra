resource "aws_cognito_user_pool" "default" {
  name                     = "default"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_domain" "default" {
  domain          = "auth.${local.public_domain}"
  user_pool_id    = aws_cognito_user_pool.default.id
  certificate_arn = aws_acm_certificate.default.arn
}

resource "aws_cognito_user_pool_client" "default" {
  name                                 = "default"
  user_pool_id                         = aws_cognito_user_pool.default.id
  callback_urls                        = local.callback_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true

}
