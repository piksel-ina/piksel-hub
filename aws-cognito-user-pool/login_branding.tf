resource "aws_cognito_managed_login_branding" "this" {
  for_each = {
    for client in var.clients : client.name => client
  }

  client_id    = aws_cognito_user_pool_client.this[each.key].id
  user_pool_id = aws_cognito_user_pool.this.id

  # Main Logo
  asset {
    category   = "PAGE_HEADER_LOGO"
    color_mode = "LIGHT"
    extension  = "PNG"
    bytes      = filebase64("${path.module}/config/assets/Logo_Badan_Informasi_Geospasial.png")
  }

  # Page Background
  asset {
    category   = "PAGE_BACKGROUND"
    color_mode = "LIGHT"
    extension  = "JPEG"
    bytes      = filebase64("${path.module}/config/assets/main-background.jpg")
  }

  # Form Logo
  asset {
    category   = "FORM_LOGO"
    color_mode = "LIGHT"
    extension  = "PNG"
    bytes      = filebase64("${path.module}/config/assets/form-logo.png")
  }

  # Favicon (ICO)
  asset {
    category   = "FAVICON_ICO"
    color_mode = "LIGHT"
    extension  = "ICO"
    bytes      = filebase64("${path.module}/config/assets/favicon.ico")
  }

  settings = jsonencode({
    componentClasses = {
      input = {
        borderRadius = 2
        lightMode = {
          defaults = {
            borderColor = "ccccccff"
          }
        }
      }
      buttons = {
        borderRadius = 2
      }
      focusState = {
        lightMode = {
          borderColor = "1971c2ff"
        }
      }
      link = {
        lightMode = {
          defaults = {
            textColor = "1971c2ff"
          }
          hover = {
            textColor = "115293ff"
          }
        }
      }
      inputDescription = {
        lightMode = {
          textColor = "666666ff"
        }
      }
      inputLabel = {
        lightMode = {
          textColor = "1a1a1aff"
        }
      }
      optionControls = {
        lightMode = {
          defaults = {
            borderColor     = "7d8998ff"
            backgroundColor = "ffffffff"
          }
          selected = {
            backgroundColor = "1971c2ff"
            foregroundColor = "ffffffff"
          }
        }
      }
      statusIndicator = {
        lightMode = {
          error = {
            backgroundColor = "fff7f7ff"
            borderColor     = "d91515ff"
            indicatorColor  = "d91515ff"
          }
          success = {
            backgroundColor = "f2fcf3ff"
            borderColor     = "037f0cff"
            indicatorColor  = "037f0cff"
          }
          warning = {
            backgroundColor = "fffce9ff"
            borderColor     = "8d6605ff"
            indicatorColor  = "8d6605ff"
          }
        }
      }
    }
    components = {
      favicon = {
        enabledTypes = ["ICO"]
      }
      primaryButton = {
        lightMode = {
          defaults = {
            backgroundColor = "1971c2ff"
            textColor       = "ffffffff"
          }
          hover = {
            backgroundColor = "115293ff"
            textColor       = "ffffffff"
          }
          active = {
            backgroundColor = "0a3d70ff"
            textColor       = "ffffffff"
          }
        }
      }
      secondaryButton = {
        lightMode = {
          defaults = {
            backgroundColor = "ffffffff"
            borderColor     = "1971c2ff"
            textColor       = "1971c2ff"
          }
          hover = {
            backgroundColor = "e7f5ffff"
            borderColor     = "115293ff"
            textColor       = "115293ff"
          }
          active = {
            backgroundColor = "d0ebffff"
            borderColor     = "0a3d70ff"
            textColor       = "0a3d70ff"
          }
        }
      }
      pageText = {
        lightMode = {
          bodyColor        = "333333ff"
          headingColor     = "1a1a1aff"
          descriptionColor = "666666ff"
        }
      }
      pageHeader = {
        logo = {
          enabled  = true
          location = "CENTER"
        }
      }
      form = {
        logo = {
          enabled  = true
          position = "TOP"
          location = "CENTER"
        }
        borderRadius = 2
      }
      pageBackground = {
        image = {
          enabled = true
        }
        lightMode = {
          color = "f5f5f5ff"
        }
      }
    }
  })
}